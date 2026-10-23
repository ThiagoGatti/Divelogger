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

## Testar no celular (Android)

A URL do servidor é definida **na hora de gerar o app**, com `--dart-define-from-file`.
O menu *Build > Flutter > Build APK* do Android Studio **não** passa esse argumento: o APK sai sem a URL e o login
mostra "Sem conexão com o servidor (host)". Gere pelo terminal:

```powershell
cd frontend
# APK de teste (debug) -> backend na AWS por HTTP (só para testes!)
powershell -ExecutionPolicy Bypass -File .\scripts\apk-teste.ps1
# APK de release -> exige HTTPS (env/prod.json)
powershell -ExecutionPolicy Bypass -File .\scripts\apk-release.ps1
```

| Build | URL usada | HTTP permitido? |
|---|---|---|
| `flutter run` / `--debug` com `env/aws-http.json` | a do arquivo | sim (só no debug) |
| `--release` com `env/prod.json` | a do arquivo (**https**) | **não** |
| sem `--dart-define` | placeholder / `10.0.2.2` (emulador) | — o app avisa que falta a URL |

### HTTPS sem domínio próprio (CloudFront)

Para ter uma URL https rapidamente (sem comprar domínio): CloudFront → *Create distribution* →
origem = `divelog-env.eba-p82cgkkx.sa-east-1.elasticbeanstalk.com`, protocolo de origem **HTTP only**,
*Viewer protocol policy* = Redirect HTTP to HTTPS, métodos permitidos = **GET, HEAD, OPTIONS, PUT, POST, PATCH, DELETE**,
*Cache policy* = **CachingDisabled**, *Origin request policy* = **AllViewer**.
Quando ficar *Deployed*, use `https://dxxxxxxxx.cloudfront.net` em `env/prod.json` e em `ApiConfig.productionUrl`.
(Os nomes das opções podem variar um pouco no console.) Para a loja, o ideal continua sendo um domínio próprio + ACM + ALB.

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
| Mergulhos registrados | **ilimitados** | ilimitados |
| Fotos por mergulho | 2 (`PLAN_FREE_MAX_PHOTOS`) | 10 (`PLAN_PREMIUM_MAX_PHOTOS`) |
| Fotos de cada Dive Site | 2 (`PLAN_FREE_MAX_SITE_PHOTOS`) | todas |
| Informações do local | básicas (descrição, tipo, nível, profundidade, nota) | **avançadas** (melhor época, visibilidade, temperatura, corrente, certificação, fauna/flora, como chegar, infraestrutura, dicas, avisos) |
| Estatísticas do perfil | básicas | avançadas |

As informações avançadas e as fotos extras dos locais **nem saem do servidor** para usuários Free
(`extended` vem nulo e `extendedLocked` avisa o app). PREMIUM com `plan_expires_at` vencido vale como FREE.
Limites de fotos retornam HTTP 403 com `code: PLAN_LIMIT`. ADMIN enxerga tudo.

Privacidade dos mergulhos (`diveVisibility`):

| Valor | Quem vê |
|---|---|
| `PRIVATE` | só o próprio usuário |
| `FRIENDS` | quem ele segue **e** que também o segue de volta (amigo = seguimento mútuo) |
| `FOLLOWERS` (padrão) | qualquer pessoa que o segue (seguir é imediato, como no Letterboxd / Last.fm) |
| `PUBLIC` | qualquer usuário do app |

A regra é aplicada no servidor em **todo** acesso a dados de outra pessoa (mergulhos, listas, feed, reações e comentários).
Mergulho que você não pode ver responde 404, como se não existisse. O perfil (nome, @usuário, bio, contadores e 4 favoritos) é visível para todos.

## Offline e sincronização

O app funciona sem internet para o que importa no barco ou em locais remotos:

- **Registrar, editar e excluir mergulhos offline** (com fotos). Tudo fica numa fila no aparelho e é enviado
  sozinho ao abrir o app, ao voltar para o app e quando a conexão retorna (faixa "Sincronizando…" / "aguardando envio").
- **Dive Sites no aparelho:** a última lista recebida fica em cache automático (dá para escolher o local ao registrar
  um mergulho sem sinal). Em cada local, o botão **Salvar offline** (ícone de download) guarda os detalhes completos e as
  fotos, como uma playlist offline; a aba Sites tem o filtro "Salvos offline".
- **Fotos:** são copiadas para o app e enviadas na sincronização. Foto recusada pelo servidor (ex.: limite do plano) é
  descartada com aviso, e o mergulho é mantido.
- **Sessão:** o app abre offline mesmo com o token vencido (24 h). Ao voltar a internet pede novo login; a fila é preservada.
- **Idempotência:** mergulhos criados offline levam um `clientId`; reenvios após queda de rede não duplicam.
- **Erros definitivos** (ex.: local desativado enquanto estava offline) aparecem em "Problemas de sincronização"
  (tentar de novo ou descartar).

Limites atuais: reações, comentários, feed, listas, avaliações e o mapa (as imagens do mapa) exigem internet; fotos já
vistas ou salvas offline continuam aparecendo.

## Mapa (MapTiler) e coordenadas dos locais

O mapa usa o **MapTiler** (satélite, híbrido e mapa de ruas). A chave entra na hora de gerar o app, nos arquivos
`frontend/env/*.json` (`MAPTILER_KEY`) ou com `--dart-define=MAPTILER_KEY=...`. Sem chave, o app cai no OpenStreetMap
(sem satélite), só para desenvolvimento.

1. Crie a conta em maptiler.com, gere uma **chave de API** (*Account > API keys*) e cole em `MAPTILER_KEY`.
2. O **plano gratuito é para uso não comercial** (desenvolvimento e testes). Para publicar nas lojas, assine um plano pago.
3. A chave fica dentro do app (qualquer app móvel é assim): use uma chave exclusiva deste app, ative os alertas de uso
   no painel e troque a chave se houver abuso.
4. A atribuição "© MapTiler © OpenStreetMap contributors" aparece sobre o mapa e não deve ser removida.

**Como marcar o ponto de um Dive Site (admin):** no formulário do local, *Marcar o ponto no mapa (satélite)*. O mapa se
move sob uma cruz fixa e as coordenadas mostradas são as do ponto sob a cruz (6 casas decimais). Dá para colar
coordenadas de outro app (`-25.4991, -48.3202` ou `25°29'56"S 48°19'12"W`) e usar o GPS (leitura nova, com a precisão
mostrada em metros). Na página do local há um mini mapa para conferir a posição.

## Operadoras

ADMIN cadastra operadoras (**nome e foto**) em Perfil, Configurações, Operadoras e as vincula aos locais onde
atuam (pela própria operadora ou na página do local, botão *Gerenciar*). Todos os usuários veem as operadoras na página
do Dive Site e podem abrir a página da operadora.

## Banco de dados: restrições de enum

O Hibernate cria uma restrição CHECK para cada campo `@Enumerated(STRING)` e o `ddl-auto=update` não a atualiza quando um
valor novo é acrescentado. O componente `SchemaFixer` remove essas restrições (idempotente, a cada inicialização), e a
validação continua no Java. Ele sai quando o projeto adotar migrations (Flyway).

## Notas de avaliação

Todas as notas vão de **0,5 a 5 estrelas, em passos de meia estrela** (0 = sem nota).

- **Local do mergulho** (`notaLocal` + `comentarioLocal`): vira a avaliação do usuário no Dive Site (a mais recente vale).
  A página do local mostra a **média** de todos os mergulhadores.
- **Minha experiência** (`notaExperiencia`): quanto o mergulho foi bom para o usuário; aparece junto com o mergulho (para quem pode vê-lo) e não altera a nota do local.

As notas antigas (inteiras, 1 a 5) são migradas automaticamente na primeira inicialização do backend.

## Reações

Emojis permitidos: 🤿 🌊 🐠 🔥 👏 ❤️ (uma reação por usuário em cada mergulho; tocar na sua remove).

## Endpoints principais

- `GET /api/me` — usuário atual + permissões do plano; `PATCH /api/me/profile` — @usuário, bio e privacidade
- `GET /api/dive-sites[?includeInactive=true (admin)]`, `GET /api/dive-sites/{id}`
- `POST|PUT /api/dive-sites[/{id}]`, `PATCH /api/dive-sites/{id}/ativo` — **ADMIN**
- `POST /api/dive-sites/{id}/images/presign`, `POST /api/dive-sites/{id}/images`, `DELETE /api/dive-sites/{id}/images/{imageId}` — **ADMIN**
- `GET /api/dive-logs/me`, `POST /api/dive-logs`, `GET|PUT|DELETE /api/dive-logs/{id}` — somente do próprio usuário
- `POST /api/dive-logs/{id}/images/presign`, `POST /api/dive-logs/{id}/images`, `DELETE /api/dive-logs/{id}/images/{imageId}`
- `GET /api/site-reviews/{siteId}`, `PUT|DELETE /api/site-reviews/{siteId}/me` — avaliações (nota 1–5 + comentário) de locais
- `GET|POST /api/lists`, `GET|PUT|DELETE /api/lists/{id}`, `POST|DELETE /api/lists/{id}/items`, `PUT /api/lists/{id}/items/order` — listas (ranqueadas ou não)
- `GET /api/lists/wishlist`, `POST /api/lists/wishlist/items`, `DELETE /api/lists/wishlist/items/site/{siteId}` — "Quero mergulhar"
- `PUT|DELETE /api/users/{id}/follow` — seguir / deixar de seguir (imediato); amigo = seguimento mútuo
- `GET /api/users/search?q=`, `GET /api/users/{id}/profile|followers|following|friends|dive-logs|lists|favorites`
- `GET /api/feed?page=&size=` — mergulhos de quem eu sigo (respeitando a privacidade de cada um)
- `GET /api/dive-logs/{id}/social`, `PUT|DELETE /api/dive-logs/{id}/reaction`, `GET|POST /api/dive-logs/{id}/comments`, `DELETE /api/dive-logs/{id}/comments/{commentId}`
- `GET /api/lists/favorites`, `PUT /api/lists/favorites` — até 4 locais favoritos; `GET|POST|DELETE /api/lists/visited…` — "Já mergulhei"
- `GET /api/operators`, `GET /api/operators/{id}`; `POST|PUT|PATCH /api/operators…`, `PUT /api/operators/{id}/sites`, `…/photo` — escrita só **ADMIN**
- `PUT /api/dive-sites/{id}/operators` — vincula operadoras ao local (**ADMIN**)
- `PATCH /api/admin/users/{id}/role` — dar/remover ADMIN (**ADMIN**; o usuário precisa entrar de novo)
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
