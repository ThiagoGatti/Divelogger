package com.log.diverr.diver.users;

import com.log.diverr.diver.users.dtos.CreateUserDto;
import com.log.diverr.diver.users.dtos.UserResponseDto;
import com.log.diverr.diver.users.usecases.UserUsecases;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private final UserUsecases userUsecases;

    public UserController(UserUsecases userUsecases) {
        this.userUsecases = userUsecases;
    }

    @PostMapping
    public ResponseEntity<UserResponseDto> createUser(
            @RequestBody CreateUserDto dto
    ) {
        UserResponseDto response = userUsecases.execute(dto);

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(response);
    }
}