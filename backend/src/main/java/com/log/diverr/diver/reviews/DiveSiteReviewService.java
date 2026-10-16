package com.log.diverr.diver.reviews;

import com.log.diverr.diver.common.ApiException;
import com.log.diverr.diver.divesites.domain.DiveSiteModel;
import com.log.diverr.diver.divesites.repository.DiveSiteRepository;
import com.log.diverr.diver.reviews.ReviewDtos.ReviewDto;
import com.log.diverr.diver.reviews.ReviewDtos.ReviewRequestDto;
import com.log.diverr.diver.reviews.ReviewDtos.ReviewsResponseDto;
import com.log.diverr.diver.users.domain.UserModel;
import com.log.diverr.diver.users.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
public class DiveSiteReviewService {

    private final DiveSiteReviewRepository repository;
    private final DiveSiteRepository siteRepository;
    private final UserRepository userRepository;

    public DiveSiteReviewService(
            DiveSiteReviewRepository repository,
            DiveSiteRepository siteRepository,
            UserRepository userRepository
    ) {
        this.repository = repository;
        this.siteRepository = siteRepository;
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public ReviewsResponseDto list(UUID siteId, Long userId, boolean isAdmin) {
        DiveSiteModel site = visibleSite(siteId, isAdmin);
        return build(site.getId(), userId);
    }

    @Transactional
    public ReviewsResponseDto upsertMine(UUID siteId, Long userId, ReviewRequestDto dto) {
        DiveSiteModel site = visibleSite(siteId, false);
        UserModel user = userRepository.findById(userId)
                .orElseThrow(() -> ApiException.unauthorized("Usuário não encontrado"));

        DiveSiteReviewModel review = repository.findByDiveSiteIdAndUserId(siteId, userId)
                .orElseGet(() -> {
                    DiveSiteReviewModel r = new DiveSiteReviewModel();
                    r.setDiveSite(site);
                    r.setUser(user);
                    return r;
                });

        review.setRating(dto.rating());
        review.setTexto(dto.texto() == null || dto.texto().isBlank() ? null : dto.texto().trim());
        review.setUpdatedAt(LocalDateTime.now());
        repository.saveAndFlush(review);

        return build(siteId, userId);
    }

    @Transactional
    public ReviewsResponseDto deleteMine(UUID siteId, Long userId) {
        repository.findByDiveSiteIdAndUserId(siteId, userId).ifPresent(repository::delete);
        repository.flush();
        return build(siteId, userId);
    }

    /** Moderação: o autor ou um ADMIN podem remover. */
    @Transactional
    public ReviewsResponseDto deleteAny(UUID siteId, UUID reviewId, Long userId, boolean isAdmin) {
        DiveSiteReviewModel review = repository.findById(reviewId)
                .filter(r -> r.getDiveSite().getId().equals(siteId))
                .orElseThrow(() -> ApiException.notFound("Avaliação não encontrada"));

        if (!isAdmin && !review.getUser().getId().equals(userId)) {
            throw ApiException.forbidden("Você não pode remover esta avaliação");
        }
        repository.delete(review);
        repository.flush();
        return build(siteId, userId);
    }

    // ---------------- util ----------------

    private DiveSiteModel visibleSite(UUID siteId, boolean isAdmin) {
        DiveSiteModel site = siteRepository.findById(siteId)
                .orElseThrow(() -> ApiException.notFound("Dive site não encontrado"));
        if (!site.isAtivo() && !isAdmin) {
            throw ApiException.notFound("Dive site não encontrado");
        }
        return site;
    }

    private ReviewsResponseDto build(UUID siteId, Long viewerId) {
        List<ReviewDto> items = repository.findTop100ByDiveSiteIdOrderByCreatedAtDesc(siteId).stream()
                .map(r -> toDto(r, viewerId))
                .toList();

        ReviewDto mine = items.stream().filter(ReviewDto::mine).findFirst().orElse(null);

        var agg = repository.aggregateFor(siteId);
        Double average = agg.map(a -> round1(a.getAverage())).orElse(null);
        long count = agg.map(a -> a.getTotal() == null ? 0L : a.getTotal()).orElse(0L);

        return new ReviewsResponseDto(average, count, mine, items);
    }

    private ReviewDto toDto(DiveSiteReviewModel r, Long viewerId) {
        UserModel u = r.getUser();
        String first = u.getNomeCompleto() == null ? "Mergulhador" : u.getNomeCompleto().trim().split("\\s+")[0];
        return new ReviewDto(
                r.getId(),
                u.getId(),
                first,
                u.getUsername(),
                r.getRating(),
                r.getTexto(),
                r.getCreatedAt(),
                u.getId().equals(viewerId)
        );
    }

    public static Double round1(Double v) {
        return v == null ? null : Math.round(v * 10.0) / 10.0;
    }
}
