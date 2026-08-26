package com.log.diverr.diver.divelogs.usecases;

import com.log.diverr.diver.divelogs.domain.DiveLogModel;
import com.log.diverr.diver.divelogs.dtos.CreateDiveLogDto;
import com.log.diverr.diver.divelogs.dtos.DiveLogResponseDto;
import com.log.diverr.diver.divesites.domain.DiveSiteModel;
import com.log.diverr.diver.divesites.repository.DiveSiteRepository;
import com.log.diverr.diver.users.domain.UserModel;
import com.log.diverr.diver.users.repository.UserRepository;
import com.log.diverr.diver.divelogs.repository.DiveLogRepository;
import org.springframework.stereotype.Service;

@Service
public class CreateDiveLogUseCase {

    private final DiveLogRepository diveLogRepository;
    private final UserRepository userRepository;
    private final DiveSiteRepository diveSiteRepository;

    public CreateDiveLogUseCase(
            DiveLogRepository diveLogRepository,
            UserRepository userRepository,
            DiveSiteRepository diveSiteRepository
    ) {
        this.diveLogRepository = diveLogRepository;
        this.userRepository = userRepository;
        this.diveSiteRepository = diveSiteRepository;
    }

    public DiveLogResponseDto execute(CreateDiveLogDto dto) {

        UserModel user = userRepository.findById(dto.userId())
                .orElseThrow(() -> new RuntimeException("Usuário não encontrado"));

        DiveSiteModel diveSite = diveSiteRepository.findById(dto.diveSiteId())
                .orElseThrow(() -> new RuntimeException("Dive site não encontrado"));

        DiveLogModel diveLog = new DiveLogModel();

        diveLog.setUser(user);
        diveLog.setDiveSite(diveSite);

        diveLog.setDataHora(dto.dataHora());
        diveLog.setDuracaoMinutos(dto.duracaoMinutos());

        diveLog.setProfundidadeMaxima(dto.profundidadeMaxima());
        diveLog.setProfundidadeMedia(dto.profundidadeMedia());

        diveLog.setVisibilidade(dto.visibilidade());
        diveLog.setTemperaturaAgua(dto.temperaturaAgua());

        diveLog.setCorrente(dto.corrente());
        diveLog.setTipoAgua(dto.tipoAgua());
        diveLog.setTipoEntrada(dto.tipoEntrada());
        diveLog.setTipoGas(dto.tipoGas());

        diveLog.setPressaoInicial(dto.pressaoInicial());
        diveLog.setPressaoFinal(dto.pressaoFinal());

        diveLog.setAvaliacao(dto.avaliacao());
        diveLog.setObservacoes(dto.observacoes());

        DiveLogModel saved = diveLogRepository.save(diveLog);

        return DiveLogResponseDto.from(saved);
    }
}