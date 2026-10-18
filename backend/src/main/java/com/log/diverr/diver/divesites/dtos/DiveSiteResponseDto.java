package com.log.diverr.diver.divesites.dtos;

import com.log.diverr.diver.divesites.domain.DiveSiteImageModel;
import com.log.diverr.diver.divesites.domain.DiveSiteModel;
import com.log.diverr.diver.storage.ImageDto;
import com.log.diverr.diver.storage.ImageStorageService;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

/**
 * O conteúdo depende de quem pede:
 *  - images: limitado a maxPhotos (Free); totalImages informa quantas existem de fato
 *  - extended: só vem para Premium/ADMIN; extendedLocked avisa o app que há conteúdo bloqueado
 */
public record DiveSiteResponseDto(
        UUID id,
        String nome,
        String descricao,
        String pais,
        String estado,
        String cidade,
        BigDecimal latitude,
        BigDecimal longitude,
        Double profundidadeMaxima,
        DiveSiteModel.TipoDiveSite tipo,
        DiveSiteModel.NivelDificuldade nivel,
        boolean ativo,
        List<ImageDto> images,
        int totalImages,
        Double ratingAverage,
        long ratingCount,
        DiveSiteExtendedDto extended,
        boolean extendedLocked,
        List<com.log.diverr.diver.operators.OperatorDtos.OperatorSummaryDto> operators
) {
    /** O que o espectador pode ver. */
    public record Access(boolean extended, int maxPhotos) {
        public static Access admin() {
            return new Access(true, 100);
        }
    }

    public static DiveSiteResponseDto from(
            DiveSiteModel site,
            ImageStorageService storage,
            Access access,
            Double ratingAverage,
            long ratingCount
    ) {
        List<DiveSiteImageModel> all = site.getImages();
        List<ImageDto> visible = all.stream()
                .limit(access.maxPhotos())
                .map(i -> new ImageDto(i.getId(), storage.urlFor(i.getStorageKey())))
                .toList();

        return new DiveSiteResponseDto(
                site.getId(),
                site.getNome(),
                site.getDescricao(),
                site.getPais(),
                site.getEstado(),
                site.getCidade(),
                site.getLatitude(),
                site.getLongitude(),
                site.getProfundidadeMaxima(),
                site.getTipo(),
                site.getNivel(),
                site.isAtivo(),
                visible,
                all.size(),
                ratingAverage,
                ratingCount,
                access.extended() ? DiveSiteExtendedDto.from(site) : null,
                !access.extended() && site.hasExtendedInfo(),
                site.getOperators().stream()
                        .filter(com.log.diverr.diver.operators.OperatorModel::isAtivo)
                        .sorted((a, b) -> a.getNome().compareToIgnoreCase(b.getNome()))
                        .map(o -> com.log.diverr.diver.operators.OperatorDtos.OperatorSummaryDto.from(o, storage))
                        .toList()
        );
    }
}
