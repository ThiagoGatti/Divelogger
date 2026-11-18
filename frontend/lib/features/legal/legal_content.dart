// Gerado a partir do mesmo texto das páginas públicas /privacidade.html e /termos.html do backend.
// MODELO: revise com um advogado e preencha os campos entre colchetes antes de publicar.

class LegalSection {
  final String heading;
  final List<String> paragraphs;
  const LegalSection({required this.heading, required this.paragraphs});
}

class LegalDocument {
  final String title;
  final String updated;
  final String intro;
  final List<LegalSection> sections;
  const LegalDocument({
    required this.title,
    required this.updated,
    required this.intro,
    required this.sections,
  });
}

const LegalDocument kPrivacyPolicy = LegalDocument(
  title: "Política de Privacidade",
  updated: "Última atualização: [DATA]",
  intro: "Esta Política explica como o Diverr (o “app”) coleta, usa, compartilha e protege os seus dados pessoais, em conformidade com a Lei Geral de Proteção de Dados (Lei nº 13.709/2018, “LGPD”). Ao criar uma conta ou usar o app, você declara que leu esta Política.",
  sections: [
    LegalSection(
      heading: "1. Quem é o responsável pelos dados",
      paragraphs: [
        "O controlador dos dados é [NOME DA EMPRESA OU RESPONSÁVEL], [CNPJ/CPF], com sede em [ENDEREÇO]. Contato para assuntos de privacidade: [E-MAIL DE CONTATO]. Encarregado pelo tratamento de dados (DPO): [NOME DO ENCARREGADO], [E-MAIL DE CONTATO].",
      ],
    ),
    LegalSection(
      heading: "2. Dados que coletamos",
      paragraphs: [
        "Conta: nome, e-mail, senha (guardada apenas de forma criptografada, com hash), @usuário, bio, foto de perfil e, se você informar, telefone e data de nascimento.",
        "Login com Google: nome, e-mail e identificador da sua conta Google. Não recebemos a sua senha do Google.",
        "Conteúdo que você cria: mergulhos (local, data, profundidade, duração, condições, notas, observações), fotos, avaliações e comentários de locais, reações, comentários em mergulhos, listas e favoritos.",
        "Relações sociais: quem você segue e quem segue você.",
        "Localização: usamos o GPS do aparelho somente quando você aciona “Minha localização” no mapa ou ao marcar um ponto. Não coletamos a sua localização em segundo plano.",
        "Dados técnicos: endereço IP, tipo de aparelho e sistema, registros de acesso e de erros, usados para segurança e para o funcionamento do serviço.",
        "Dados guardados no aparelho: cache de locais e a fila de mergulhos registrados sem internet, que ficam no seu celular até serem sincronizados.",
      ],
    ),
    LegalSection(
      heading: "3. Para que usamos os dados e em que base legal",
      paragraphs: [
        "Prestar o serviço (criar sua conta, guardar seu diário de mergulhos, mostrar locais e mapas, recursos sociais): execução de contrato.",
        "Recursos opcionais, como foto de perfil, localização e login com Google: consentimento, que você pode retirar a qualquer momento.",
        "Segurança, prevenção a fraudes e abusos, e melhoria do app: legítimo interesse.",
        "Cumprir obrigações legais e responder a ordens de autoridades: obrigação legal.",
      ],
    ),
    LegalSection(
      heading: "4. Com quem compartilhamos",
      paragraphs: [
        "Outros usuários: o seu perfil básico (nome, @usuário, bio, foto, contadores de seguidores e locais favoritos) é visível para os usuários do app. Os seus mergulhos só são vistos por quem a sua configuração de privacidade permitir: somente você, seus amigos, seus seguidores ou qualquer usuário.",
        "Prestadores de serviço que operam o app para nós: Amazon Web Services (hospedagem, banco de dados e armazenamento de fotos), MapTiler (mapas; recebe as requisições de imagens do mapa, o que inclui seu endereço IP e a área visualizada), Google (login) e provedor de envio de e-mails (recuperação de senha).",
        "Autoridades, quando houver determinação legal.",
        "Não vendemos os seus dados pessoais.",
      ],
    ),
    LegalSection(
      heading: "5. Transferência internacional",
      paragraphs: [
        "Nossos servidores ficam em data centers da AWS e alguns prestadores estão fora do Brasil. Nesses casos, adotamos as salvaguardas previstas na LGPD.",
      ],
    ),
    LegalSection(
      heading: "6. Por quanto tempo guardamos",
      paragraphs: [
        "Mantemos os dados enquanto a sua conta existir. Ao excluir a conta, apagamos ou anonimizamos os dados pessoais, salvo quando a lei exigir a guarda por mais tempo. Cópias de segurança podem permanecer por até [PRAZO] dias.",
      ],
    ),
    LegalSection(
      heading: "7. Seus direitos",
      paragraphs: [
        "Você pode, a qualquer momento: confirmar que tratamos seus dados; acessá-los; corrigi-los; pedir anonimização, bloqueio ou eliminação; pedir a portabilidade; saber com quem compartilhamos; retirar o consentimento; e se opor a um tratamento. Para exercer qualquer direito, escreva para [E-MAIL DE CONTATO]. Você também pode reclamar à Autoridade Nacional de Proteção de Dados (ANPD).",
      ],
    ),
    LegalSection(
      heading: "8. Segurança",
      paragraphs: [
        "Usamos conexão criptografada (HTTPS), senhas com hash, controle de acesso e fotos em armazenamento privado com links temporários. Nenhum sistema é totalmente seguro; em caso de incidente relevante, comunicaremos você e a ANPD conforme a lei.",
      ],
    ),
    LegalSection(
      heading: "9. Menores de idade",
      paragraphs: [
        "O Diverr é destinado a maiores de [18] anos. Se tomarmos conhecimento de dados de menores coletados sem autorização do responsável legal, vamos excluí-los.",
      ],
    ),
    LegalSection(
      heading: "10. Publicidade e rastreamento",
      paragraphs: [
        "O app não exibe anúncios de terceiros e não usa SDKs de rastreamento publicitário. [CONFIRMAR antes de publicar.]",
      ],
    ),
    LegalSection(
      heading: "11. Alterações desta Política",
      paragraphs: [
        "Podemos atualizar esta Política. Quando a mudança for relevante, avisaremos pelo app. A data da última atualização fica no topo.",
      ],
    ),
    LegalSection(
      heading: "12. Contato",
      paragraphs: [
        "Dúvidas ou pedidos sobre privacidade: [E-MAIL DE CONTATO].",
      ],
    ),
  ],
);

const LegalDocument kTermsOfUse = LegalDocument(
  title: "Termos de Uso",
  updated: "Última atualização: [DATA]",
  intro: "Estes Termos regulam o uso do Diverr (o “app”). Ao criar uma conta ou usar o app, você concorda com eles e com a Política de Privacidade.",
  sections: [
    LegalSection(
      heading: "1. O serviço",
      paragraphs: [
        "O Diverr é um diário de mergulho com mapa de locais, avaliações, listas e recursos sociais (seguir, reagir e comentar). Algumas funções são exclusivas do plano Premium.",
      ],
    ),
    LegalSection(
      heading: "2. Sua conta",
      paragraphs: [
        "Você deve ter [18] anos ou mais, informar dados verdadeiros e manter a sua senha em segredo. Você é responsável pela atividade da sua conta. Avise-nos se suspeitar de uso indevido.",
      ],
    ),
    LegalSection(
      heading: "3. Seu conteúdo",
      paragraphs: [
        "Você continua dono do que publica (mergulhos, fotos, comentários). Ao publicar, você nos autoriza a hospedar, armazenar e exibir esse conteúdo no app, de acordo com as suas configurações de privacidade, e a processá-lo para operar o serviço. Você declara ter os direitos sobre o que publica, incluindo o direito de imagem das pessoas que aparecem nas suas fotos.",
      ],
    ),
    LegalSection(
      heading: "4. Conduta e moderação",
      paragraphs: [
        "É proibido publicar conteúdo ilegal, ofensivo, discriminatório, de assédio, de violência, sexualmente explícito, que viole direitos autorais ou a privacidade de terceiros, além de spam e tentativas de fraude ou de acesso indevido.",
        "Podemos remover conteúdo e suspender ou encerrar contas que violem estes Termos. Para denunciar conteúdo ou usuários, escreva para [E-MAIL DE CONTATO].",
      ],
    ),
    LegalSection(
      heading: "5. Segurança no mergulho",
      paragraphs: [
        "Mergulhar é uma atividade de risco. As informações de locais, condições, profundidades, operadoras e avaliações do app são colaborativas e podem estar incompletas, desatualizadas ou incorretas. O app não substitui treinamento, certificação, planejamento do mergulho, equipamento adequado, avaliação das condições no dia nem a orientação de profissionais habilitados. Você mergulha por sua conta e risco e é responsável pelas suas decisões.",
      ],
    ),
    LegalSection(
      heading: "6. Planos e pagamentos",
      paragraphs: [
        "O plano Free é gratuito. O plano Premium é pago e cobrado pela loja de aplicativos (Google Play ou App Store), conforme preço e período exibidos na contratação. O cancelamento e os reembolsos seguem as regras da loja e a legislação do consumidor.",
      ],
    ),
    LegalSection(
      heading: "7. Propriedade intelectual",
      paragraphs: [
        "O app, a marca Diverr, o design e o código pertencem a [NOME DA EMPRESA OU RESPONSÁVEL] ou a seus licenciantes. Não é permitido copiá-los ou usá-los sem autorização. Mapas são fornecidos por MapTiler e pelos colaboradores do OpenStreetMap.",
      ],
    ),
    LegalSection(
      heading: "8. Disponibilidade e mudanças",
      paragraphs: [
        "Buscamos manter o app disponível, mas não garantimos funcionamento ininterrupto. Podemos alterar, suspender ou descontinuar recursos, com aviso quando a mudança for relevante.",
      ],
    ),
    LegalSection(
      heading: "9. Limitação de responsabilidade",
      paragraphs: [
        "Na extensão permitida pela lei, não nos responsabilizamos por danos decorrentes do uso do app, de informações de terceiros, de conteúdo publicado por usuários ou da prática do mergulho. Isso não afeta os direitos do consumidor garantidos por lei.",
      ],
    ),
    LegalSection(
      heading: "10. Encerramento",
      paragraphs: [
        "Você pode deixar de usar o app e excluir a sua conta quando quiser. Podemos suspender ou encerrar contas que violem estes Termos.",
      ],
    ),
    LegalSection(
      heading: "11. Lei e foro",
      paragraphs: [
        "Estes Termos seguem as leis do Brasil. Fica eleito o foro da comarca de [CIDADE/UF], ressalvado o direito do consumidor de propor ações no foro do seu domicílio.",
      ],
    ),
    LegalSection(
      heading: "12. Contato",
      paragraphs: [
        "Dúvidas sobre estes Termos: [E-MAIL DE CONTATO].",
      ],
    ),
  ],
);
