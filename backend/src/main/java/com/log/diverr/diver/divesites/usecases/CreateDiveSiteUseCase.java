package com.log.diverr.diver.divesites.usecases;

import com.log.diverr.diver.divesites.domain.DiveSiteModel;
import com.log.diverr.diver.divesites.dtos.CreateDiveSiteDto;
import com.log.diverr.diver.divesites.dtos.DiveSiteResponseDto;
import com.log.diverr.diver.divesites.repository.DiveSiteRepository;
import com.log.diverr.diver.users.domain.UserModel;
import com.log.diverr.diver.users.repository.UserRepository;
import org.springframework.stereotype.Service;

@Service
public class CreateDiveSiteUseCase {

    private final DiveSiteRepository diveSiteRepository;
    private final UserRepository userRepository;

    public CreateDiveSiteUseCase(
            DiveSiteRepository diveSiteRepository,
            UserRepository userRepository
    ) {
        this.diveSiteRepository = diveSiteRepository;
        this.userRepository = userRepository;
    }

    public DiveSiteResponseDto execute(CreateDiveSiteDto dto) {

        UserModel user = userRepository.findById(dto.createdBy())
                .orElseThrow(() -> new RuntimeException("Usuário não encontrado"));

        DiveSiteModel diveSite = new DiveSiteModel();

        diveSite.setNome(dto.nome());
        diveSite.setDescricao(dto.descricao());
        diveSite.setPais(dto.pais());
        diveSite.setEstado(dto.estado());
        diveSite.setCidade(dto.cidade());
        diveSite.setLatitude(dto.latitude());
        diveSite.setLongitude(dto.longitude());
        diveSite.setProfundidadeMaxima(dto.profundidadeMaxima());
        diveSite.setTipo(dto.tipo());
        diveSite.setCreatedBy(user);

        DiveSiteModel saved = diveSiteRepository.save(diveSite);

        return DiveSiteResponseDto.from(saved);
    }
}