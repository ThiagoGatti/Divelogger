package com.log.diverr.diver.divesites;

import com.log.diverr.diver.divesites.dtos.CreateDiveSiteDto;
import com.log.diverr.diver.divesites.dtos.DiveSiteResponseDto;
import com.log.diverr.diver.divesites.domain.DiveSiteModel;
import com.log.diverr.diver.divesites.repository.DiveSiteRepository;
import com.log.diverr.diver.divesites.usecases.CreateDiveSiteUseCase;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/dive-sites")
public class DiveSiteController {

    private final CreateDiveSiteUseCase createDiveSiteUseCase;
    private final DiveSiteRepository diveSiteRepository;

    public DiveSiteController(
            CreateDiveSiteUseCase createDiveSiteUseCase,
            DiveSiteRepository diveSiteRepository
    ) {
        this.createDiveSiteUseCase = createDiveSiteUseCase;
        this.diveSiteRepository = diveSiteRepository;
    }

    @PostMapping
    public ResponseEntity<DiveSiteResponseDto> create(
            @RequestBody CreateDiveSiteDto dto
    ) {
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(createDiveSiteUseCase.execute(dto));
    }

    @GetMapping
    public ResponseEntity<List<DiveSiteResponseDto>> findAll() {

        List<DiveSiteResponseDto> response = diveSiteRepository.findAll()
                .stream()
                .map(DiveSiteResponseDto::from)
                .toList();

        return ResponseEntity.ok(response);
    }

    @GetMapping("/{id}")
    public ResponseEntity<DiveSiteResponseDto> findById(
            @PathVariable UUID id
    ) {

        DiveSiteModel diveSite = diveSiteRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Dive site não encontrado"));

        return ResponseEntity.ok(
                DiveSiteResponseDto.from(diveSite)
        );
    }
}