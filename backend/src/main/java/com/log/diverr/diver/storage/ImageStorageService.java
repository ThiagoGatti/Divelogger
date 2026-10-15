package com.log.diverr.diver.storage;

import com.log.diverr.diver.common.ApiException;
import jakarta.annotation.PreDestroy;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.HeadObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.model.S3Exception;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;
import software.amazon.awssdk.services.s3.presigner.model.PresignedPutObjectRequest;
import software.amazon.awssdk.services.s3.presigner.model.PutObjectPresignRequest;

import java.time.Duration;
import java.util.Map;
import java.util.UUID;

/**
 * Imagens ficam em um bucket S3 PRIVADO. O app nunca recebe credenciais:
 *  - upload: URL pré-assinada de PUT (10 min), direto do celular para o S3;
 *  - leitura: URL pré-assinada de GET (1 h) devolvida nas respostas da API.
 * No banco guardamos só a "key" do objeto.
 * Credenciais: perfil IAM da instância do Beanstalk (sem chaves no código).
 */
@Service
public class ImageStorageService {

    private static final Logger log = LoggerFactory.getLogger(ImageStorageService.class);

    private static final Map<String, String> EXTENSIONS = Map.of(
            "image/jpeg", "jpg",
            "image/png", "png",
            "image/webp", "webp"
    );

    private final String bucket;
    private final Region region;
    private final long maxBytes;

    private S3Presigner presigner;
    private S3Client client;

    public ImageStorageService(
            @Value("${app.s3.bucket:}") String bucket,
            @Value("${app.s3.region:sa-east-1}") String region,
            @Value("${app.s3.max-image-bytes:8388608}") long maxBytes
    ) {
        this.bucket = bucket == null ? "" : bucket.trim();
        this.region = Region.of(region);
        this.maxBytes = maxBytes;
    }

    public boolean isEnabled() {
        return !bucket.isBlank();
    }

    public long getMaxBytes() {
        return maxBytes;
    }

    /** Gera uma key nova no formato {prefix}/{uuid}.{ext}. O prefix já contém dono/recurso. */
    public String newKey(String prefix, String contentType) {
        return prefix + UUID.randomUUID() + "." + extensionFor(contentType);
    }

    public PresignResponseDto presignUpload(String key, String contentType, long sizeBytes) {
        requireEnabled();
        extensionFor(contentType);
        if (sizeBytes > maxBytes) {
            throw ApiException.badRequest("Imagem muito grande (máx. " + (maxBytes / 1024 / 1024) + " MB)");
        }

        PutObjectRequest put = PutObjectRequest.builder()
                .bucket(bucket)
                .key(key)
                .contentType(contentType)
                .contentLength(sizeBytes)
                .build();

        PresignedPutObjectRequest presigned = presigner().presignPutObject(
                PutObjectPresignRequest.builder()
                        .signatureDuration(Duration.ofMinutes(10))
                        .putObjectRequest(put)
                        .build()
        );

        return new PresignResponseDto(presigned.url().toString(), key, contentType);
    }

    /** URL temporária de leitura. Retorna null se o S3 não estiver configurado ou falhar. */
    public String urlFor(String key) {
        if (!isEnabled() || key == null) {
            return null;
        }
        try {
            GetObjectRequest get = GetObjectRequest.builder().bucket(bucket).key(key).build();
            return presigner().presignGetObject(
                    GetObjectPresignRequest.builder()
                            .signatureDuration(Duration.ofHours(1))
                            .getObjectRequest(get)
                            .build()
            ).url().toString();
        } catch (Exception e) {
            log.warn("Não foi possível gerar URL da imagem {}: {}", key, e.getMessage());
            return null;
        }
    }

    /** Confirma que o upload terminou e valida o tamanho real do objeto. */
    public void assertUploaded(String key) {
        requireEnabled();
        try {
            long size = client().headObject(
                    HeadObjectRequest.builder().bucket(bucket).key(key).build()
            ).contentLength();
            if (size > maxBytes) {
                delete(key);
                throw ApiException.badRequest("Imagem muito grande");
            }
        } catch (S3Exception e) {
            if (e.statusCode() == 404) {
                throw ApiException.badRequest("Imagem não encontrada no armazenamento. Envie novamente.");
            }
            log.error("Falha ao verificar imagem {}", key, e);
            throw new ApiException(HttpStatus.BAD_GATEWAY, "Falha ao acessar o armazenamento de imagens");
        }
    }

    /** Remoção "best effort": nunca deve impedir a remoção do registro no banco. */
    public void delete(String key) {
        if (!isEnabled() || key == null) {
            return;
        }
        try {
            client().deleteObject(DeleteObjectRequest.builder().bucket(bucket).key(key).build());
        } catch (Exception e) {
            log.warn("Não foi possível apagar a imagem {}: {}", key, e.getMessage());
        }
    }

    private String extensionFor(String contentType) {
        String ext = contentType == null ? null : EXTENSIONS.get(contentType.toLowerCase());
        if (ext == null) {
            throw ApiException.badRequest("Formato de imagem não suportado (use JPEG, PNG ou WebP)");
        }
        return ext;
    }

    private void requireEnabled() {
        if (!isEnabled()) {
            throw new ApiException(HttpStatus.SERVICE_UNAVAILABLE, "Armazenamento de imagens não configurado");
        }
    }

    private synchronized S3Presigner presigner() {
        if (presigner == null) {
            presigner = S3Presigner.builder().region(region).build();
        }
        return presigner;
    }

    private synchronized S3Client client() {
        if (client == null) {
            client = S3Client.builder().region(region).build();
        }
        return client;
    }

    @PreDestroy
    void close() {
        if (presigner != null) presigner.close();
        if (client != null) client.close();
    }
}
