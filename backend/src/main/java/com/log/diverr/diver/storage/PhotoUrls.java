package com.log.diverr.diver.storage;

import com.log.diverr.diver.users.domain.UserModel;
import org.springframework.stereotype.Component;

import java.util.UUID;

/**
 * Atalho para montar a URL (temporária) da foto de perfil nos DTOs, sem precisar passar o serviço de
 * armazenamento por todos os lugares. photoId é estável (serve de chave de cache no app).
 */
@Component
public class PhotoUrls {

    private static ImageStorageService storage;

    public PhotoUrls(ImageStorageService storage) {
        PhotoUrls.storage = storage;
    }

    public static String url(UserModel user) {
        if (user == null || user.getProfilePhotoKey() == null || storage == null) {
            return null;
        }
        return storage.urlFor(user.getProfilePhotoKey());
    }

    public static String id(UserModel user) {
        if (user == null || user.getProfilePhotoKey() == null) {
            return null;
        }
        return UUID.nameUUIDFromBytes(user.getProfilePhotoKey().getBytes()).toString();
    }
}
