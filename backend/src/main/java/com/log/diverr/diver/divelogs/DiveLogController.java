package com.log.diverr.diver.divelogs;

import com.log.diverr.diver.divelogs.domain.DiveLogModel;
import com.log.diverr.diver.divelogs.dtos.CreateDiveLogDto;
import com.log.diverr.diver.divelogs.dtos.DiveLogResponseDto;
import com.log.diverr.diver.divelogs.repository.DiveLogRepository;
import com.log.diverr.diver.divelogs.usecases.CreateDiveLogUseCase;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/dive-logs")
public class DiveLogController {

    private final CreateDiveLogUseCase createDiveLogUseCase;
    private final DiveLogRepository diveLogRepository;

    public DiveLogController(
            CreateDiveLogUseCase createDiveLogUseCase,
            DiveLogRepository diveLogRepository
    ) {
        this.createDiveLogUseCase = createDiveLogUseCase;
        this.diveLogRepository = diveLogRepository;
    }

    @PostMapping
    public ResponseEntity<DiveLogResponseDto> create(
            @RequestBody CreateDiveLogDto dto
    ) {

        DiveLogResponseDto response =
                createDiveLogUseCase.execute(dto);

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(response);
    }

    @GetMapping("/{id}")
    public ResponseEntity<DiveLogResponseDto> findById(
            @PathVariable UUID id
    ) {

        DiveLogModel diveLog = diveLogRepository.findById(id)
                .orElseThrow(() ->
                        new RuntimeException("Dive log não encontrado")
                );

        return ResponseEntity.ok(
                DiveLogResponseDto.from(diveLog)
        );
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<List<DiveLogResponseDto>> findByUser(
            @PathVariable Long userId
    ) {

        List<DiveLogResponseDto> response =
                diveLogRepository.findByUserId(userId)
                        .stream()
                        .map(DiveLogResponseDto::from)
                        .toList();

        return ResponseEntity.ok(response);
    }

    @GetMapping("/site/{diveSiteId}")
    public ResponseEntity<List<DiveLogResponseDto>> findByDiveSite(
            @PathVariable UUID diveSiteId
    ) {

        List<DiveLogResponseDto> response =
                diveLogRepository.findByDiveSiteId(diveSiteId)
                        .stream()
                        .map(DiveLogResponseDto::from)
                        .toList();

        return ResponseEntity.ok(response);
    }
}