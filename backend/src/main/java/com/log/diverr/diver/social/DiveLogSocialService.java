package com.log.diverr.diver.social;

import com.log.diverr.diver.common.ApiException;
import com.log.diverr.diver.divelogs.domain.DiveLogModel;
import com.log.diverr.diver.divelogs.repository.DiveLogRepository;
import com.log.diverr.diver.social.SocialDtos.CommentDto;
import com.log.diverr.diver.social.SocialDtos.SocialSummaryDto;
import com.log.diverr.diver.users.domain.UserModel;
import com.log.diverr.diver.users.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;

/** Reações (emoji) e comentários em mergulhos. Só quem PODE VER o mergulho pode reagir/comentar. */
@Service
public class DiveLogSocialService {

    /** Reações permitidas. */
    public static final List<String> EMOJIS = List.of("🤿", "🌊", "🐠", "🔥", "👏", "❤️");

    private final DiveLogRepository logs;
    private final UserRepository users;
    private final VisibilityService visibility;
    private final DiveLogReactionRepository reactions;
    private final DiveLogCommentRepository comments;

    public DiveLogSocialService(
            DiveLogRepository logs,
            UserRepository users,
            VisibilityService visibility,
            DiveLogReactionRepository reactions,
            DiveLogCommentRepository comments
    ) {
        this.logs = logs;
        this.users = users;
        this.visibility = visibility;
        this.reactions = reactions;
        this.comments = comments;
    }

    // ---------------- resumo ----------------

    @Transactional(readOnly = true)
    public SocialSummaryDto summary(UUID logId, Long viewerId) {
        visibleLog(logId, viewerId);
        return summaries(List.of(logId), viewerId).get(logId);
    }

    /** Resumo em lote (usado pelo feed): evita uma consulta por mergulho. */
    @Transactional(readOnly = true)
    public Map<UUID, SocialSummaryDto> summaries(Collection<UUID> ids, Long viewerId) {
        Map<UUID, SocialSummaryDto> result = new HashMap<>();
        if (ids.isEmpty()) {
            return result;
        }

        Map<UUID, Map<String, Long>> byLog = new HashMap<>();
        for (var row : reactions.countsFor(ids)) {
            byLog.computeIfAbsent(row.getLogId(), k -> new LinkedHashMap<>())
                    .put(row.getEmoji(), row.getTotal());
        }

        Map<UUID, String> mine = new HashMap<>();
        for (var r : reactions.mineFor(ids, viewerId)) {
            mine.put(r.getDiveLog().getId(), r.getEmoji());
        }

        Map<UUID, Long> commentCounts = new HashMap<>();
        for (var row : comments.countsFor(ids)) {
            commentCounts.put(row.getLogId(), row.getTotal());
        }

        for (UUID id : ids) {
            result.put(id, new SocialSummaryDto(
                    byLog.getOrDefault(id, Map.of()),
                    mine.get(id),
                    commentCounts.getOrDefault(id, 0L)
            ));
        }
        return result;
    }

    // ---------------- reações ----------------

    @Transactional
    public SocialSummaryDto react(UUID logId, Long viewerId, String emoji) {
        DiveLogModel log = visibleLog(logId, viewerId);
        if (!EMOJIS.contains(emoji)) {
            throw ApiException.badRequest("Reação inválida");
        }

        UserModel viewer = users.findById(viewerId)
                .orElseThrow(() -> ApiException.unauthorized("Usuário não encontrado"));

        DiveLogReactionModel reaction = reactions.findByDiveLogIdAndUserId(logId, viewerId)
                .orElseGet(() -> {
                    DiveLogReactionModel r = new DiveLogReactionModel();
                    r.setDiveLog(log);
                    r.setUser(viewer);
                    return r;
                });
        reaction.setEmoji(emoji);
        reactions.saveAndFlush(reaction);

        return summaries(List.of(logId), viewerId).get(logId);
    }

    @Transactional
    public SocialSummaryDto removeReaction(UUID logId, Long viewerId) {
        visibleLog(logId, viewerId);
        reactions.findByDiveLogIdAndUserId(logId, viewerId).ifPresent(reactions::delete);
        reactions.flush();
        return summaries(List.of(logId), viewerId).get(logId);
    }

    // ---------------- comentários ----------------

    @Transactional(readOnly = true)
    public List<CommentDto> listComments(UUID logId, Long viewerId, boolean isAdmin) {
        DiveLogModel log = visibleLog(logId, viewerId);
        return toDtos(log, viewerId, isAdmin);
    }

    @Transactional
    public List<CommentDto> addComment(UUID logId, Long viewerId, String texto, boolean isAdmin) {
        DiveLogModel log = visibleLog(logId, viewerId);
        UserModel viewer = users.findById(viewerId)
                .orElseThrow(() -> ApiException.unauthorized("Usuário não encontrado"));

        DiveLogCommentModel c = new DiveLogCommentModel();
        c.setDiveLog(log);
        c.setUser(viewer);
        c.setTexto(texto.trim());
        comments.saveAndFlush(c);

        return toDtos(log, viewerId, isAdmin);
    }

    /** Pode apagar: o autor do comentário, o dono do mergulho ou um ADMIN (moderação). */
    @Transactional
    public List<CommentDto> deleteComment(UUID logId, UUID commentId, Long viewerId, boolean isAdmin) {
        DiveLogModel log = visibleLog(logId, viewerId);
        DiveLogCommentModel c = comments.findById(commentId)
                .filter(x -> x.getDiveLog().getId().equals(logId))
                .orElseThrow(() -> ApiException.notFound("Comentário não encontrado"));

        boolean author = c.getUser().getId().equals(viewerId);
        boolean owner = log.getUser().getId().equals(viewerId);
        if (!author && !owner && !isAdmin) {
            throw ApiException.forbidden("Você não pode apagar este comentário");
        }
        comments.delete(c);
        comments.flush();
        return toDtos(log, viewerId, isAdmin);
    }

    // ---------------- util ----------------

    /** 404 (e não 403) para não revelar a existência de mergulhos que o usuário não pode ver. */
    private DiveLogModel visibleLog(UUID logId, Long viewerId) {
        DiveLogModel log = logs.findById(logId)
                .orElseThrow(() -> ApiException.notFound("Dive log não encontrado"));
        if (!visibility.canViewDives(viewerId, log.getUser())) {
            throw ApiException.notFound("Dive log não encontrado");
        }
        return log;
    }

    private List<CommentDto> toDtos(DiveLogModel log, Long viewerId, boolean isAdmin) {
        boolean owner = log.getUser().getId().equals(viewerId);
        return comments.findByDiveLogIdOrderByCreatedAtAsc(log.getId()).stream().map(c -> {
            UserModel u = c.getUser();
            String first = u.getNomeCompleto() == null ? "Mergulhador" : u.getNomeCompleto().trim().split("\\s+")[0];
            boolean mine = u.getId().equals(viewerId);
            return new CommentDto(
                    c.getId(), u.getId(), first, u.getUsername(),
                    com.log.diverr.diver.storage.PhotoUrls.url(u), com.log.diverr.diver.storage.PhotoUrls.id(u),
                    c.getTexto(), c.getCreatedAt(),
                    mine, mine || owner || isAdmin);
        }).toList();
    }
}
