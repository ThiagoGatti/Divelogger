# Diverr

Flutter mobile app + Spring Boot API + PostgreSQL.

## Local development

### 1. Database

```bash
cd backend
docker compose up -d
```

PostgreSQL will be available at `localhost:5432`, database `diverr`, user/password `diverr`.

### 2. API

```bash
cd backend
./mvnw spring-boot:run
```

Windows:

```bat
mvnw.cmd spring-boot:run
```

API: `http://localhost:8080`

### 3. Flutter

```bash
cd frontend
flutter pub get
flutter run
```

Android emulator uses `http://10.0.2.2:8080` by default because its `localhost` points to the emulator itself.

Physical Android/iPhone devices must use the computer's LAN IP:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.0.10:8080
```

For an iOS Simulator, use:

```bash
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8080
```

The API base URL is centralized in `frontend/lib/core/network/api_config.dart`, so changing environments later only requires changing the dart define, not every API call.

## Production (AWS Elastic Beanstalk)

Pushing to `main` deploys the backend (`.github/workflows/deploy.yml`).

**Environment properties required in Elastic Beanstalk** (Configuration > Updates, monitoring, and logging > Environment properties):

| Variable | Notes |
|---|---|
| `JWT_SECRET` | Base64, >= 32 bytes. Generate: `openssl rand -base64 48` |
| `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USERNAME`, `DB_PASSWORD` | RDS PostgreSQL |
| `DB_SSL_MODE` | `require` for RDS |
| `SERVER_PORT` | `5000` (Beanstalk Java SE default upstream port) |
| `CORS_ALLOWED_ORIGINS` | only needed for web clients |
| `ADMIN_EMAIL` (+ `ADMIN_PASSWORD`) | optional: promotes/creates the first ADMIN at startup |

Set the load balancer health check path to `/actuator/health`.

**HTTPS is mandatory for release builds.** The default `*.elasticbeanstalk.com` URL is HTTP only: add an Application Load Balancer listener on 443 with an ACM certificate and point a domain (Route 53) to it.

### Flutter against AWS

Edit `frontend/env/prod.json` (and `ApiConfig.productionUrl`) with your HTTPS URL, then:

```bash
flutter run --dart-define-from-file=env/prod.json
flutter build appbundle --dart-define-from-file=env/prod.json
```

## Imagens (Amazon S3)

As fotos ficam em um bucket S3 **privado**. O app nunca recebe credenciais: o backend gera URLs pré-assinadas
(upload de 10 min, leitura de 1 h) e o celular envia a foto direto para o S3.

Configuração única:

1. **Bucket:** S3 → Criar bucket em `sa-east-1` (ex.: `diverr-media-<sufixo>`), com **Bloquear todo acesso público** ligado.
2. **IAM:** adicione uma política em linha ao perfil da instância do Beanstalk (`aws-elasticbeanstalk-ec2-role`):

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"],
    "Resource": "arn:aws:s3:::NOME-DO-BUCKET/*"
  }]
}
```

3. **Variáveis no Beanstalk:** `S3_BUCKET=NOME-DO-BUCKET` e `S3_REGION=sa-east-1`.
   Sem `S3_BUCKET` o upload retorna 503 (útil no ambiente local).
4. Não precisa de CORS (o upload é feito pelo app nativo, não por navegador).

Chaves: `dive-logs/{userId}/{diveLogId}/{uuid}.jpg` e `dive-sites/{siteId}/{uuid}.jpg`.
Fotos enviadas mas nunca registradas ficam órfãs: crie uma regra de ciclo de vida no bucket se quiser limpeza automática.

## Perfis e planos

| | USER | ADMIN |
|---|---|---|
| Ver Dive Sites ativos, registrar mergulhos | sim | sim |
| Criar / editar / desativar Dive Sites e suas fotos | não | **sim** |
| Painel de usuários e planos (`/api/admin/**`) | não | **sim** |

| | FREE | PREMIUM |
|---|---|---|
| Mergulhos | até 30 (`PLAN_FREE_MAX_DIVE_LOGS`) | ilimitados |
| Fotos por mergulho | 3 (`PLAN_FREE_MAX_PHOTOS`) | 10 (`PLAN_PREMIUM_MAX_PHOTOS`) |
| Estatísticas | básicas | avançadas |
| Exportação | não | sim (a implementar) |

PREMIUM com `plan_expires_at` vencido vale como FREE. Os limites são aplicados no backend (HTTP 403 com `code: PLAN_LIMIT`)
e refletidos na interface a partir de `GET /api/me`.

## Endpoints principais

- `GET /api/me` — usuário atual + permissões do plano
- `GET /api/dive-sites[?includeInactive=true (admin)]`, `GET /api/dive-sites/{id}`
- `POST|PUT /api/dive-sites[/{id}]`, `PATCH /api/dive-sites/{id}/ativo` — **ADMIN**
- `POST /api/dive-sites/{id}/images/presign`, `POST /api/dive-sites/{id}/images`, `DELETE /api/dive-sites/{id}/images/{imageId}` — **ADMIN**
- `GET /api/dive-logs/me`, `POST /api/dive-logs`, `GET|PUT|DELETE /api/dive-logs/{id}` — somente do próprio usuário
- `POST /api/dive-logs/{id}/images/presign`, `POST /api/dive-logs/{id}/images`, `DELETE /api/dive-logs/{id}/images/{imageId}`
- `GET /api/admin/users`, `PATCH /api/admin/users/{id}/plan` — **ADMIN**

## Architecture

- `backend/`: Spring Boot REST API
- PostgreSQL: persistence
- `frontend/`: Flutter Android/iOS/web
- Flutter communicates with Spring through HTTP/JSON
- Authentication: email/password login returns a JWT (Bearer). The Flutter app stores it in the Keychain/Keystore (`flutter_secure_storage`) and sends it on every request.
- Offline dive logging should be implemented next with a local Flutter database and an outbox/sync queue.


--

🟢 Fase 1 — MVP funcional

Agora:

PostgreSQL ✅
Spring Boot ✅
Flutter ✅
Usuário ✅
Login ✅
Dive Sites ✅
Mapa ✅
Criar Dive Site ✅
Listar Dive Sites ✅
Criar Dive Log
Listar Dive Logs

Sem upload ainda.

🟡 Fase 2 — Imagens

Depois:

📷 foto de perfil
📷 múltiplas fotos do Dive Site
📷 múltiplas fotos do Dive Log
compressão no celular
upload
armazenamento
exclusão/troca de imagens
thumbnails/cache no Flutter
🔵 Fase 3 — Refinamento

Depois:

estatísticas
favoritos
avaliações
descoberta de Dive Sites
perfis
social
planos FREE/PREMIUM/escolas
etc.
