<?xml version="1.0" encoding="UTF-8"?>

<!--
  ╔══════════════════════════════════════════════════════════════════════════════╗
  ║              ABNT NBR 10520:2023 — FOLHA DE ESTILO XSL                     ║
  ║          Informação e documentação — Citações em documentos                ║
  ╠══════════════════════════════════════════════════════════════════════════════╣
  ║                                                                              ║
  ║  Descrição   : Folha de estilo XSLT 1.0 para formatação automática de       ║
  ║                citações e referências bibliográficas conforme a norma        ║
  ║                brasileira ABNT NBR 10520, edição de 2023.                   ║
  ║                                                                              ║
  ║  Cobertura   : — Citação direta curta  (até 3 linhas, inline)               ║
  ║                — Citação direta longa  (acima de 3 linhas, recuada)         ║
  ║                — Citação indireta / paráfrase                               ║
  ║                — Citação de citação   (apud)                                ║
  ║                — Sistema autor-data   (SOBRENOME, ano, p. X)                ║
  ║                — Sistema numérico     ([N])                                  ║
  ║                — Notas de rodapé / Notas de fim                             ║
  ║                — Referências listadas  (ABNT NBR 6023:2018)                 ║
  ║                                                                              ║
  ║  Versão      : 1.0.0                                                         ║
  ║  Codificação : UTF-8                                                         ║
  ║  Namespace   : https://abnt.org.br/nbr10520/2023                            ║
  ║  XSLT        : 1.0 (compatível com Saxon, Xalan, libxslt)                   ║
  ║                                                                              ║
  ║  Dependências: Nenhuma — folha autossuficiente                               ║
  ║                                                                              ║
  ║  Estrutura do arquivo XML de entrada esperado:                               ║
  ║    <documento>                                                                ║
  ║      <configuracao>                                                           ║
  ║        <sistema>autor-data | numerico</sistema>                              ║
  ║        <idioma>pt-BR</idioma>                                                ║
  ║      </configuracao>                                                         ║
  ║      <corpo> ... <citacao> ... </citacao> ... </corpo>                        ║
  ║      <referencias> <referencia id="..."> ... </referencia> </referencias>   ║
  ║    </documento>                                                               ║
  ║                                                                              ║
  ╚══════════════════════════════════════════════════════════════════════════════╝
-->

<xsl:stylesheet
    version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:abnt="https://abnt.org.br/nbr10520/2023"
    exclude-result-prefixes="abnt">

  <!-- ═══════════════════════════════════════════════════════════════════════
       SEÇÃO 1 — PARÂMETROS GLOBAIS E CONFIGURAÇÕES DE SAÍDA
       Todos os parâmetros podem ser sobrescritos externamente ao transformar,
       permitindo reutilização desta folha em diferentes contextos editoriais.
       ═══════════════════════════════════════════════════════════════════════ -->

  <!--
    Método de saída: HTML5 semântico, permitindo renderização em navegadores,
    sistemas de gestão de conteúdo e conversores para PDF (como Prince XML ou
    WeasyPrint). Altere para "xml" se o destino for outro processador XSLT.
  -->
  <xsl:output
      method="html"
      version="5.0"
      encoding="UTF-8"
      indent="yes"
      doctype-system="about:legacy-compat"/>

  <!--
    @param sistema-citacao
    Define o sistema de chamada bibliográfica adotado no documento.
    Valores aceitos:
      "autor-data"  → (SOBRENOME, ano)   — padrão ABNT 10520:2023 §5
      "numerico"    → [N] ou (N)          — padrão ABNT 10520:2023 §6
  -->
  <xsl:param name="sistema-citacao">
    <xsl:choose>
      <xsl:when test="/documento/configuracao/sistema">
        <xsl:value-of select="/documento/configuracao/sistema"/>
      </xsl:when>
      <xsl:otherwise>autor-data</xsl:otherwise>
    </xsl:choose>
  </xsl:param>

  <!--
    @param idioma
    Código de idioma BCP-47 para atributo lang do HTML e adaptações
    tipográficas (aspas, pontuação etc.).
  -->
  <xsl:param name="idioma">
    <xsl:choose>
      <xsl:when test="/documento/configuracao/idioma">
        <xsl:value-of select="/documento/configuracao/idioma"/>
      </xsl:when>
      <xsl:otherwise>pt-BR</xsl:otherwise>
    </xsl:choose>
  </xsl:param>

  <!--
    @param recuo-citacao-longa
    Recuo esquerdo (em centímetros) aplicado a citações diretas longas.
    NBR 10520:2023 §5.3 determina 4 cm. Altere conforme template institucional.
  -->
  <xsl:param name="recuo-citacao-longa">4cm</xsl:param>

  <!--
    @param tamanho-fonte-citacao-longa
    Corpo tipográfico para citações longas. A norma não especifica valor
    exato, mas a tradição acadêmica brasileira adota 10pt ou 11pt.
  -->
  <xsl:param name="tamanho-fonte-citacao-longa">10pt</xsl:param>

  <!--
    @param espacamento-simples
    Espaçamento de linha para citações diretas longas (NBR 10520:2023 §5.3).
  -->
  <xsl:param name="espacamento-simples">1.0</xsl:param>

  <!--
    @param titulo-referencias
    Título da seção de referências. Pode ser "REFERÊNCIAS" ou "BIBLIOGRAPHY"
    conforme idioma e norma complementar (NBR 6023:2018).
  -->
  <xsl:param name="titulo-referencias">REFERÊNCIAS</xsl:param>

  <!--
    @param mostrar-folha-estilos-inline
    Se "sim", injeta CSS inline no <head> do HTML gerado. Útil para documentos
    standalone sem acesso a arquivo .css externo.
  -->
  <xsl:param name="mostrar-folha-estilos-inline">sim</xsl:param>


  <!-- ═══════════════════════════════════════════════════════════════════════
       SEÇÃO 2 — VARIÁVEIS DERIVADAS E CONSTANTES NORMATIVAS
       Calculadas uma única vez no início da transformação para eficiência.
       ═══════════════════════════════════════════════════════════════════════ -->

  <!--
    @var prefixo-apud
    Expressão latina padronizada para citação de citação (§ 5.6 da norma).
    Conforme NBR 10520:2023, o termo deve aparecer em itálico no texto.
  -->
  <xsl:variable name="prefixo-apud">apud</xsl:variable>

  <!--
    @var prefixo-et-al
    Abreviatura latina para "e outros", usada quando há 4 ou mais autores.
    NBR 10520:2023 §5.2 — citar apenas o primeiro autor seguido de et al.
  -->
  <xsl:variable name="prefixo-et-al">et al.</xsl:variable>

  <!--
    @var marcador-pagina
    Abreviatura de "página" ou "páginas" conforme idioma e norma.
    NBR 10520:2023 determina "p." antes do número de página.
  -->
  <xsl:variable name="marcador-pagina">p.</xsl:variable>

  <!--
    @var marcador-paginas-plural
    Para intervalos de páginas: "p." é usado tanto para singular quanto plural
    na norma ABNT, diferentemente de outras normas internacionais.
  -->
  <xsl:variable name="marcador-paginas-plural">p.</xsl:variable>

  <!--
    @var marcador-sem-data
    Expressão normalizada para obras sem data de publicação identificável.
    NBR 10520:2023 — usar entre colchetes: [s.d.]
  -->
  <xsl:variable name="marcador-sem-data">[s.d.]</xsl:variable>

  <!--
    @var marcador-sem-local
    Expressão para obras sem local de publicação identificado.
    NBR 6023:2018 — [S. l.]
  -->
  <xsl:variable name="marcador-sem-local">[S. l.]</xsl:variable>

  <!--
    @var marcador-sem-editora
    Expressão para obras sem editora identificada.
    NBR 6023:2018 — [s. n.]
  -->
  <xsl:variable name="marcador-sem-editora">[s. n.]</xsl:variable>


  <!-- ═══════════════════════════════════════════════════════════════════════
       SEÇÃO 3 — TEMPLATE RAIZ: ESTRUTURA DO DOCUMENTO HTML
       Constrói o esqueleto HTML5 completo com metadados, estilos e corpo.
       ═══════════════════════════════════════════════════════════════════════ -->

  <!--
    Template principal — processa o nó raiz <documento> e gera o HTML completo.
    Todos os demais templates são chamados a partir daqui, mantendo o fluxo
    de transformação centralizado e previsível.
  -->
  <xsl:template match="/documento">
    <html lang="{$idioma}">
      <head>
        <!-- Metadados essenciais para renderização correta em navegadores -->
        <meta charset="UTF-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>

        <!-- Título do documento, extraído do elemento <titulo> se disponível -->
        <title>
          <xsl:choose>
            <xsl:when test="metadados/titulo">
              <xsl:value-of select="metadados/titulo"/>
            </xsl:when>
            <xsl:otherwise>Documento ABNT NBR 10520:2023</xsl:otherwise>
          </xsl:choose>
        </title>

        <!-- Metadados Dublin Core para interoperabilidade bibliográfica -->
        <xsl:call-template name="metadados-dublin-core"/>

        <!-- Folha de estilos inline condicional -->
        <xsl:if test="$mostrar-folha-estilos-inline = 'sim'">
          <style type="text/css">
            <xsl:call-template name="estilos-css"/>
          </style>
        </xsl:if>
      </head>

      <body>
        <!-- Cabeçalho do documento acadêmico -->
        <xsl:if test="metadados">
          <header class="documento-cabecalho" role="banner">
            <xsl:call-template name="renderizar-cabecalho-documento"/>
          </header>
        </xsl:if>

        <!-- Corpo principal com o texto e citações -->
        <main class="documento-corpo" role="main">
          <xsl:apply-templates select="corpo"/>
        </main>

        <!-- Notas de rodapé coletadas ao final (se sistema numérico) -->
        <xsl:if test="$sistema-citacao = 'numerico'">
          <aside class="notas-rodape" role="complementary"
                 aria-label="Notas de rodapé">
            <xsl:call-template name="renderizar-notas-rodape"/>
          </aside>
        </xsl:if>

        <!-- Seção de referências bibliográficas -->
        <xsl:if test="referencias/referencia">
          <section class="referencias" role="region"
                   aria-label="{$titulo-referencias}">
            <xsl:call-template name="renderizar-secao-referencias"/>
          </section>
        </xsl:if>

        <!-- Rodapé do documento -->
        <footer class="documento-rodape" role="contentinfo">
          <small>
            Formatado conforme
            <abbr title="Associação Brasileira de Normas Técnicas">ABNT</abbr>
            NBR 10520:2023 — Informação e documentação — Citações em documentos.
          </small>
        </footer>
      </body>
    </html>
  </xsl:template>


  <!-- ═══════════════════════════════════════════════════════════════════════
       SEÇÃO 4 — TEMPLATES DE METADADOS E CABEÇALHO
       ═══════════════════════════════════════════════════════════════════════ -->

  <!--
    Emite tags <meta> Dublin Core para enriquecer a semântica do documento
    e facilitar indexação por repositórios institucionais (DSpace, OJS etc.).
  -->
  <xsl:template name="metadados-dublin-core">
    <xsl:if test="metadados/titulo">
      <meta name="DC.title"   content="{metadados/titulo}"/>
    </xsl:if>
    <xsl:if test="metadados/autor">
      <meta name="DC.creator" content="{metadados/autor}"/>
    </xsl:if>
    <xsl:if test="metadados/data">
      <meta name="DC.date"    content="{metadados/data}"/>
    </xsl:if>
    <xsl:if test="metadados/instituicao">
      <meta name="DC.publisher" content="{metadados/instituicao}"/>
    </xsl:if>
    <meta name="DC.format"   content="text/html"/>
    <meta name="DC.language" content="{$idioma}"/>
    <meta name="DC.rights"   content="Norma ABNT NBR 10520:2023"/>
  </xsl:template>

  <!--
    Renderiza o bloco de identificação do documento acadêmico:
    instituição, título, autor, orientador, local e data.
    Estrutura conforme NBR 14724:2011 (trabalhos acadêmicos).
  -->
  <xsl:template name="renderizar-cabecalho-documento">
    <div class="identificacao-documento">

      <!-- Instituição de ensino superior -->
      <xsl:if test="metadados/instituicao">
        <p class="instituicao">
          <xsl:value-of select="metadados/instituicao"/>
        </p>
      </xsl:if>

      <!-- Departamento ou programa de pós-graduação -->
      <xsl:if test="metadados/departamento">
        <p class="departamento">
          <xsl:value-of select="metadados/departamento"/>
        </p>
      </xsl:if>

      <!-- Título principal do trabalho — caixa alta e negrito -->
      <xsl:if test="metadados/titulo">
        <h1 class="titulo-documento">
          <xsl:value-of select="metadados/titulo"/>
        </h1>
      </xsl:if>

      <!-- Subtítulo, se presente, separado por dois pontos -->
      <xsl:if test="metadados/subtitulo">
        <p class="subtitulo-documento">
          <xsl:value-of select="metadados/subtitulo"/>
        </p>
      </xsl:if>

      <!-- Autor(es) do trabalho -->
      <xsl:for-each select="metadados/autores/autor">
        <p class="autor-documento">
          <xsl:value-of select="."/>
        </p>
      </xsl:for-each>

      <!-- Orientador e coorientador -->
      <xsl:if test="metadados/orientador">
        <p class="orientador">
          <span class="rotulo">Orientador: </span>
          <xsl:value-of select="metadados/orientador"/>
        </p>
      </xsl:if>
      <xsl:if test="metadados/coorientador">
        <p class="coorientador">
          <span class="rotulo">Coorientador: </span>
          <xsl:value-of select="metadados/coorientador"/>
        </p>
      </xsl:if>

      <!-- Local e data de publicação -->
      <p class="local-data">
        <xsl:choose>
          <xsl:when test="metadados/local">
            <xsl:value-of select="metadados/local"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$marcador-sem-local"/>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:text>, </xsl:text>
        <xsl:choose>
          <xsl:when test="metadados/ano">
            <xsl:value-of select="metadados/ano"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$marcador-sem-data"/>
          </xsl:otherwise>
        </xsl:choose>
      </p>
    </div>
  </xsl:template>


  <!-- ═══════════════════════════════════════════════════════════════════════
       SEÇÃO 5 — PROCESSAMENTO DO CORPO DO TEXTO
       Templates para parágrafos, seções e fluxo geral do documento.
       ═══════════════════════════════════════════════════════════════════════ -->

  <!--
    Processa o elemento raiz <corpo>, mantendo a hierarquia semântica
    de seções, subseções, parágrafos e citações.
  -->
  <xsl:template match="corpo">
    <article class="corpo-texto">
      <xsl:apply-templates/>
    </article>
  </xsl:template>

  <!-- Seções de primeiro nível -->
  <xsl:template match="secao">
    <section class="secao">
      <xsl:if test="@id">
        <xsl:attribute name="id">
          <xsl:value-of select="@id"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates/>
    </section>
  </xsl:template>

  <!-- Subseções de segundo nível -->
  <xsl:template match="subsecao">
    <section class="subsecao">
      <xsl:if test="@id">
        <xsl:attribute name="id">
          <xsl:value-of select="@id"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates/>
    </section>
  </xsl:template>

  <!-- Títulos de seção numerados conforme NBR 6024 -->
  <xsl:template match="titulo[@nivel='1'] | secao/titulo[not(@nivel)]">
    <h2 class="titulo-secao">
      <xsl:if test="@numero">
        <span class="numero-secao">
          <xsl:value-of select="@numero"/>
          <xsl:text>&#160;</xsl:text>
        </span>
      </xsl:if>
      <xsl:apply-templates/>
    </h2>
  </xsl:template>

  <xsl:template match="titulo[@nivel='2'] | subsecao/titulo[not(@nivel)]">
    <h3 class="titulo-subsecao">
      <xsl:if test="@numero">
        <span class="numero-subsecao">
          <xsl:value-of select="@numero"/>
          <xsl:text>&#160;</xsl:text>
        </span>
      </xsl:if>
      <xsl:apply-templates/>
    </h3>
  </xsl:template>

  <xsl:template match="titulo[@nivel='3']">
    <h4 class="titulo-subsubsecao">
      <xsl:if test="@numero">
        <span class="numero-subsubsecao">
          <xsl:value-of select="@numero"/>
          <xsl:text>&#160;</xsl:text>
        </span>
      </xsl:if>
      <xsl:apply-templates/>
    </h4>
  </xsl:template>

  <!-- Parágrafo padrão com espaçamento conforme NBR 14724:2011 -->
  <xsl:template match="paragrafo | p">
    <p class="paragrafo">
      <xsl:apply-templates/>
    </p>
  </xsl:template>

  <!-- Texto em itálico — títulos de obras, termos estrangeiros etc. -->
  <xsl:template match="italico | em | i">
    <em><xsl:apply-templates/></em>
  </xsl:template>

  <!-- Texto em negrito — ênfase, destaques autorizados -->
  <xsl:template match="negrito | strong | b">
    <strong><xsl:apply-templates/></strong>
  </xsl:template>

  <!-- Texto sublinhado — uso limitado conforme norma -->
  <xsl:template match="sublinhado | u">
    <u><xsl:apply-templates/></u>
  </xsl:template>

  <!-- Supressão de texto em citações: reticências entre colchetes [...]  -->
  <xsl:template match="supressao">
    <span class="supressao" aria-label="trecho suprimido">[...]</span>
  </xsl:template>

  <!-- Interpolação/acréscimo do autor ao texto citado: entre colchetes -->
  <xsl:template match="interpolacao">
    <span class="interpolacao" aria-label="interpolação do autor">
      <xsl:text>[</xsl:text>
      <xsl:apply-templates/>
      <xsl:text>]</xsl:text>
    </span>
  </xsl:template>

  <!-- Grifo nosso: destaque inserido pelo autor do trabalho -->
  <xsl:template match="grifo-nosso">
    <strong class="grifo-nosso" title="grifo nosso">
      <xsl:apply-templates/>
    </strong>
    <xsl:text> </xsl:text>
    <span class="nota-grifo">(grifo nosso)</span>
  </xsl:template>

  <!-- Grifo do autor: destaque presente no original citado -->
  <xsl:template match="grifo-autor">
    <strong class="grifo-autor" title="grifo do autor">
      <xsl:apply-templates/>
    </strong>
    <xsl:text> </xsl:text>
    <span class="nota-grifo">(grifo do autor)</span>
  </xsl:template>

  <!-- Tradução livre de trecho em língua estrangeira -->
  <xsl:template match="traducao-livre">
    <span class="traducao-livre">
      <xsl:apply-templates/>
    </span>
    <xsl:text> </xsl:text>
    <span class="nota-traducao">(tradução nossa)</span>
  </xsl:template>


  <!-- ═══════════════════════════════════════════════════════════════════════
       SEÇÃO 6 — CITAÇÕES DIRETAS CURTAS (ATÉ 3 LINHAS)
       NBR 10520:2023 §5.2 — integradas ao texto entre aspas duplas.
       ═══════════════════════════════════════════════════════════════════════ -->

  <!--
    Citação direta curta no sistema AUTOR-DATA.

    Padrão de chamada no texto:
      — No início: SOBRENOME (ano, p. X) "texto citado"
      — No final:  "texto citado" (SOBRENOME, ano, p. X)

    O atributo @posicao controla o posicionamento da chamada:
      "antes"  → autor antes das aspas
      "depois" → chamada bibliográfica após as aspas (padrão)
  -->
  <xsl:template match="citacao[@tipo='direta-curta'] |
                        citacao[not(@tipo)]">
    <span class="citacao citacao-direta-curta">

      <!-- Chamada bibliográfica posicionada ANTES do texto citado -->
      <xsl:if test="@posicao = 'antes'">
        <xsl:call-template name="chamada-autor-data-antes">
          <xsl:with-param name="ref-id"  select="@ref"/>
          <xsl:with-param name="pagina"  select="@pagina"/>
          <xsl:with-param name="paginas" select="@paginas"/>
        </xsl:call-template>
        <xsl:text> </xsl:text>
      </xsl:if>

      <!-- Texto citado entre aspas duplas (padrão português brasileiro) -->
      <q class="texto-citado" cite="#{@ref}">
        <xsl:apply-templates/>
      </q>

      <!-- Chamada bibliográfica posicionada DEPOIS do texto citado -->
      <xsl:if test="not(@posicao) or @posicao = 'depois'">
        <xsl:text> </xsl:text>
        <xsl:call-template name="chamada-autor-data-depois">
          <xsl:with-param name="ref-id"  select="@ref"/>
          <xsl:with-param name="pagina"  select="@pagina"/>
          <xsl:with-param name="paginas" select="@paginas"/>
        </xsl:call-template>
      </xsl:if>

    </span>
  </xsl:template>


  <!-- ═══════════════════════════════════════════════════════════════════════
       SEÇÃO 7 — CITAÇÕES DIRETAS LONGAS (MAIS DE 3 LINHAS)
       NBR 10520:2023 §5.3 — parágrafo independente, recuado 4 cm,
       sem aspas, fonte menor, espaçamento simples.
       ═══════════════════════════════════════════════════════════════════════ -->

  <!--
    Citação direta longa: renderizada como bloco independente <blockquote>
    estilizado conforme as prescrições tipográficas da norma.

    Atributos relevantes no XML de entrada:
      @ref       → ID da referência bibliográfica (obrigatório)
      @pagina    → número de página única (ex: "42")
      @paginas   → intervalo de páginas   (ex: "42-45")
      @posicao   → "antes" | "depois" (padrão: depois)
  -->
  <xsl:template match="citacao[@tipo='direta-longa']">
    <figure class="citacao-direta-longa-container">

      <blockquote
          class="citacao citacao-direta-longa"
          cite="#{@ref}"
          role="blockquote">

        <!-- Chamada posicionada antes (rara, mas prevista na norma) -->
        <xsl:if test="@posicao = 'antes'">
          <p class="chamada-antes">
            <xsl:call-template name="chamada-autor-data-antes">
              <xsl:with-param name="ref-id"  select="@ref"/>
              <xsl:with-param name="pagina"  select="@pagina"/>
              <xsl:with-param name="paginas" select="@paginas"/>
            </xsl:call-template>
          </p>
        </xsl:if>

        <!-- Conteúdo textual da citação -->
        <xsl:apply-templates/>

        <!-- Chamada posicionada depois (padrão NBR 10520:2023) -->
        <xsl:if test="not(@posicao) or @posicao = 'depois'">
          <footer class="chamada-bibliografica-longa">
            <xsl:call-template name="chamada-autor-data-depois">
              <xsl:with-param name="ref-id"  select="@ref"/>
              <xsl:with-param name="pagina"  select="@pagina"/>
              <xsl:with-param name="paginas" select="@paginas"/>
            </xsl:call-template>
          </footer>
        </xsl:if>

      </blockquote>

      <!-- Legenda acessível opcional para leitores de tela -->
      <figcaption class="sr-only">
        Citação direta longa. Fonte:
        <xsl:call-template name="texto-chamada-acessivel">
          <xsl:with-param name="ref-id"  select="@ref"/>
          <xsl:with-param name="pagina"  select="@pagina"/>
          <xsl:with-param name="paginas" select="@paginas"/>
        </xsl:call-template>
      </figcaption>

    </figure>
  </xsl:template>


  <!-- ═══════════════════════════════════════════════════════════════════════
       SEÇÃO 8 — CITAÇÕES INDIRETAS / PARÁFRASES
       NBR 10520:2023 §5.4 — sem aspas, sem recuo especial, com chamada.
       ═══════════════════════════════════════════════════════════════════════ -->

  <!--
    Citação indireta (paráfrase): reproduz a ideia de outrem com as palavras
    do autor do trabalho. Não usa aspas nem recuo. A chamada bibliográfica
    é obrigatória, mas a indicação de página é opcional conforme a norma.
  -->
  <xsl:template match="citacao[@tipo='indireta'] |
                        citacao[@tipo='parafrrase'] |
                        citacao[@tipo='parafrases']">
    <span class="citacao citacao-indireta">

      <!-- Chamada antes do conteúdo parafraseado -->
      <xsl:if test="@posicao = 'antes'">
        <xsl:call-template name="chamada-autor-data-antes">
          <xsl:with-param name="ref-id"  select="@ref"/>
          <xsl:with-param name="pagina"  select="@pagina"/>
          <xsl:with-param name="paginas" select="@paginas"/>
        </xsl:call-template>
        <xsl:text> </xsl:text>
      </xsl:if>

      <!-- Texto parafraseado — sem marcação visual especial -->
      <xsl:apply-templates/>

      <!-- Chamada após o conteúdo parafraseado (mais comum) -->
      <xsl:if test="not(@posicao) or @posicao = 'depois'">
        <xsl:text> </xsl:text>
        <xsl:call-template name="chamada-autor-data-depois">
          <xsl:with-param name="ref-id"  select="@ref"/>
          <xsl:with-param name="pagina"  select="@pagina"/>
          <xsl:with-param name="paginas" select="@paginas"/>
        </xsl:call-template>
      </xsl:if>

    </span>
  </xsl:template>


  <!-- ═══════════════════════════════════════════════════════════════════════
       SEÇÃO 9 — CITAÇÃO DE CITAÇÃO (APUD)
       NBR 10520:2023 §5.6 — uso do "apud" quando o original é inacessível.
       ═══════════════════════════════════════════════════════════════════════ -->

  <!--
    Citação de citação: indica que o autor do trabalho não teve acesso
    direto à fonte primária, citando-a por intermédio de fonte secundária.

    Estrutura da chamada:
      AUTOR-ORIGINAL (ano apud AUTOR-SECUNDARIO, ano, p. X)

    No XML de entrada:
      @ref-original  → autor e ano da fonte que não foi consultada
      @ref           → ID da referência consultada (fonte secundária)
      @autor-original → SOBRENOME do autor original
      @ano-original   → ano da obra original
      @pagina / @paginas → localização na fonte secundária

    ATENÇÃO: NBR 10520:2023 recomenda evitar este tipo de citação.
    Nas referências, lista-se apenas a obra efetivamente consultada.
  -->
  <xsl:template match="citacao[@tipo='apud'] |
                        citacao-apud">
    <span class="citacao citacao-apud">

      <!-- Texto da citação (direta ou indireta) -->
      <xsl:if test="@subtipo = 'direta'">
        <q class="texto-citado-apud" cite="#{@ref}">
          <xsl:apply-templates/>
        </q>
      </xsl:if>
      <xsl:if test="not(@subtipo) or @subtipo = 'indireta'">
        <xsl:apply-templates/>
      </xsl:if>

      <!-- Construção da chamada com apud -->
      <xsl:text> (</xsl:text>

      <!-- Autor e ano da obra original não consultada -->
      <span class="autor-original">
        <xsl:choose>
          <xsl:when test="@autor-original">
            <xsl:call-template name="formatar-sobrenome-citacao">
              <xsl:with-param name="sobrenome" select="@autor-original"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>AUTOR ORIGINAL</xsl:otherwise>
        </xsl:choose>
      </span>

      <xsl:if test="@ano-original">
        <xsl:text>, </xsl:text>
        <span class="ano-original">
          <xsl:value-of select="@ano-original"/>
        </span>
      </xsl:if>

      <!-- Conector "apud" em itálico conforme convenção tipográfica -->
      <xsl:text> </xsl:text>
      <em class="apud-termo">
        <xsl:value-of select="$prefixo-apud"/>
      </em>
      <xsl:text> </xsl:text>

      <!-- Autor e ano da obra efetivamente consultada (fonte secundária) -->
      <xsl:call-template name="construir-chamada-referencia">
        <xsl:with-param name="ref-id"  select="@ref"/>
        <xsl:with-param name="pagina"  select="@pagina"/>
        <xsl:with-param name="paginas" select="@paginas"/>
      </xsl:call-template>

      <xsl:text>)</xsl:text>
    </span>
  </xsl:template>


  <!-- ═══════════════════════════════════════════════════════════════════════
       SEÇÃO 10 — SISTEMA NUMÉRICO DE CHAMADA
       NBR 10520:2023 §6 — números sobrescritos ou entre colchetes/parênteses.
       ═══════════════════════════════════════════════════════════════════════ -->

  <!--
    Chamada numérica: gera número sequencial para citações no sistema numérico.
    O número é calculado pela posição do elemento <citacao> no documento.

    Formatos disponíveis via atributo @formato-numerico na configuração:
      "sobrescrito"  → ¹ ² ³ (padrão tipográfico científico)
      "colchetes"    → [1] [2] (padrão ABNT alternativo)
      "parenteses"   → (1) (2) (padrão ISO 690)
  -->
  <xsl:template match="citacao[@sistema='numerico'] |
                        citacao[/documento/configuracao/sistema='numerico']">

    <xsl:variable name="numero-sequencial">
      <xsl:number
          level="any"
          count="citacao[@sistema='numerico'] |
                 citacao[/documento/configuracao/sistema='numerico']"
          from="corpo"/>
    </xsl:variable>

    <xsl:variable name="formato-numerico">
      <xsl:choose>
        <xsl:when test="/documento/configuracao/formato-numerico">
          <xsl:value-of select="/documento/configuracao/formato-numerico"/>
        </xsl:when>
        <xsl:otherwise>sobrescrito</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- Texto da citação (direta curta ou indireta) -->
    <xsl:if test="@subtipo = 'direta'">
      <q class="texto-citado-numerico" cite="#{@ref}">
        <xsl:apply-templates/>
      </q>
    </xsl:if>
    <xsl:if test="not(@subtipo) or @subtipo = 'indireta'">
      <xsl:apply-templates/>
    </xsl:if>

    <!-- Geração do marcador numérico conforme formato configurado -->
    <xsl:choose>

      <!-- Número sobrescrito — padrão mais comum em ciências exatas -->
      <xsl:when test="$formato-numerico = 'sobrescrito'">
        <sup class="chamada-numerica chamada-numerica-sobrescrito">
          <a href="#ref-{@ref}"
             class="link-referencia"
             aria-label="Ver referência {$numero-sequencial}">
            <xsl:value-of select="$numero-sequencial"/>
          </a>
        </sup>
      </xsl:when>

      <!-- Número entre colchetes — alternativa ABNT -->
      <xsl:when test="$formato-numerico = 'colchetes'">
        <span class="chamada-numerica chamada-numerica-colchetes">
          <a href="#ref-{@ref}"
             class="link-referencia"
             aria-label="Ver referência {$numero-sequencial}">
            <xsl:text>[</xsl:text>
            <xsl:value-of select="$numero-sequencial"/>
            <xsl:text>]</xsl:text>
          </a>
        </span>
      </xsl:when>

      <!-- Número entre parênteses -->
      <xsl:otherwise>
        <span class="chamada-numerica chamada-numerica-parenteses">
          <a href="#ref-{@ref}"
             class="link-referencia"
             aria-label="Ver referência {$numero-sequencial}">
            <xsl:text>(</xsl:text>
            <xsl:value-of select="$numero-sequencial"/>
            <xsl:text>)</xsl:text>
          </a>
        </span>
      </xsl:otherwise>

    </xsl:choose>

  </xsl:template>


  <!-- ═══════════════════════════════════════════════════════════════════════
       SEÇÃO 11 — NOTAS DE RODAPÉ E NOTAS DE FIM
       NBR 10520:2023 §7 — notas explicativas e/ou bibliográficas.
       ═══════════════════════════════════════════════════════════════════════ -->

  <!--
    Marca de nota de rodapé no texto (indicador sobrescrito numérico).
    NBR 10520:2023 §7.1 — notas são numeradas em ordem crescente,
    podendo reiniciar a cada capítulo ou ser contínuas no documento.
  -->
  <xsl:template match="nota | nota-rodape">

    <xsl:variable name="numero-nota">
      <xsl:number level="any" count="nota | nota-rodape" from="corpo"/>
    </xsl:variable>

    <!-- Indicador no texto — sobrescrito, com âncora para a nota -->
    <sup class="indicador-nota" id="indicador-nota-{$numero-nota}">
      <a href="#nota-{$numero-nota}"
         class="link-nota"
         aria-describedby="nota-{$numero-nota}"
         aria-label="Nota de rodapé {$numero-nota}">
        <xsl:value-of select="$numero-nota"/>
      </a>
    </sup>

  </xsl:template>

  <!--
    Renderiza a seção de notas de rodapé ao final do documento
    ou ao final de cada capítulo, conforme configuração.
  -->
  <xsl:template name="renderizar-notas-rodape">
    <xsl:if test="//nota | //nota-rodape">
      <div class="notas-rodape-lista" role="list"
           aria-label="Notas de rodapé">
        <hr class="separador-notas" aria-hidden="true"/>
        <ol class="lista-notas">
          <xsl:for-each select="//nota | //nota-rodape">
            <xsl:variable name="num">
              <xsl:number level="any" count="nota | nota-rodape" from="corpo"/>
            </xsl:variable>
            <li class="item-nota" id="nota-{$num}" role="listitem">
              <!-- Número da nota -->
              <span class="numero-nota" aria-hidden="true">
                <xsl:value-of select="$num"/>
              </span>
              <xsl:text> </xsl:text>
              <!-- Conteúdo da nota (texto explicativo ou referência) -->
              <span class="conteudo-nota">
                <xsl:apply-templates/>
              </span>
              <!-- Link de retorno ao indicador no texto -->
              <a href="#indicador-nota-{$num}"
                 class="retorno-nota"
                 aria-label="Voltar ao texto na nota {$num}">
                &#8617;<!--  ↩ -->
              </a>
            </li>
          </xsl:for-each>
        </ol>
      </div>
    </xsl:if>
  </xsl:template>


  <!-- ═══════════════════════════════════════════════════════════════════════
       SEÇÃO 12 — CHAMADAS BIBLIOGRÁFICAS (SISTEMA AUTOR-DATA)
       Lógica centralizada de construção das chamadas no texto.
       ═══════════════════════════════════════════════════════════════════════ -->

  <!--
    Chamada ANTES do texto citado: "SOBRENOME (ano, p. X) afirma que..."
    Neste formato, somente o ano (e página) vai entre parênteses.
    O sobrenome fica fora dos parênteses em CAIXA ALTA.

    NBR 10520:2023 §5.2.1 — exemplo: Santos (2021, p. 42) argumenta...
  -->
  <xsl:template name="chamada-autor-data-antes">
    <xsl:param name="ref-id"/>
    <xsl:param name="pagina"/>
    <xsl:param name="paginas"/>

    <span class="chamada-bibliografica chamada-antes">
      <!-- Sobrenome em caixa alta fora dos parênteses -->
      <xsl:call-template name="obter-sobrenome-referencia">
        <xsl:with-param name="ref-id" select="$ref-id"/>
      </xsl:call-template>
      <!-- Ano e página entre parênteses -->
      <xsl:text> (</xsl:text>
      <xsl:call-template name="obter-ano-referencia">
        <xsl:with-param name="ref-id" select="$ref-id"/>
      </xsl:call-template>
      <xsl:call-template name="formatar-localizacao-pagina">
        <xsl:with-param name="pagina"  select="$pagina"/>
        <xsl:with-param name="paginas" select="$paginas"/>
      </xsl:call-template>
      <xsl:text>)</xsl:text>
    </span>
  </xsl:template>

  <!--
    Chamada DEPOIS do texto citado: "...texto citado" (SOBRENOME, ano, p. X)
    Toda a chamada vai entre parênteses.

    NBR 10520:2023 §5.2.2 — exemplo: (SANTOS, 2021, p. 42)
  -->
  <xsl:template name="chamada-autor-data-depois">
    <xsl:param name="ref-id"/>
    <xsl:param name="pagina"/>
    <xsl:param name="paginas"/>

    <span class="chamada-bibliografica chamada-depois">
      <xsl:text>(</xsl:text>
      <xsl:call-template name="construir-chamada-referencia">
        <xsl:with-param name="ref-id"  select="$ref-id"/>
        <xsl:with-param name="pagina"  select="$pagina"/>
        <xsl:with-param name="paginas" select="$paginas"/>
      </xsl:call-template>
      <xsl:text>)</xsl:text>
    </span>
  </xsl:template>

  <!--
    Constrói o conteúdo interno da chamada: SOBRENOME, ano, p. X
    Usado tanto para chamadas após texto quanto dentro do apud.
  -->
  <xsl:template name="construir-chamada-referencia">
    <xsl:param name="ref-id"/>
    <xsl:param name="pagina"/>
    <xsl:param name="paginas"/>

    <!-- Tenta encontrar a referência correspondente pelo ID -->
    <xsl:variable name="referencia" select="//referencia[@id=$ref-id]"/>

    <xsl:choose>
      <!-- Referência encontrada — extrai dados normalizados -->
      <xsl:when test="$referencia">
        <a href="#ref-{$ref-id}" class="link-referencia-texto">
          <!-- Sobrenome do primeiro autor em caixa alta -->
          <xsl:call-template name="obter-sobrenome-referencia">
            <xsl:with-param name="ref-id" select="$ref-id"/>
          </xsl:call-template>

          <!-- et al. quando há mais de 3 autores -->
          <xsl:if test="count($referencia/autores/autor) &gt; 3">
            <xsl:text> </xsl:text>
            <em class="et-al">
              <xsl:value-of select="$prefixo-et-al"/>
            </em>
          </xsl:if>

          <!-- Vírgula separadora -->
          <xsl:text>, </xsl:text>

          <!-- Ano de publicação -->
          <xsl:call-template name="obter-ano-referencia">
            <xsl:with-param name="ref-id" select="$ref-id"/>
          </xsl:call-template>
        </a>
      </xsl:when>

      <!-- Referência não encontrada — placeholder de aviso editorial -->
      <xsl:otherwise>
        <span class="referencia-nao-encontrada" title="Referência não localizada no documento">
          <xsl:value-of select="$ref-id"/>
          <xsl:text>, [ANO]</xsl:text>
        </span>
      </xsl:otherwise>
    </xsl:choose>

    <!-- Localização: página ou intervalo de páginas -->
    <xsl:call-template name="formatar-localizacao-pagina">
      <xsl:with-param name="pagina"  select="$pagina"/>
      <xsl:with-param name="paginas" select="$paginas"/>
    </xsl:call-template>

  </xsl:template>

  <!--
    Retorna o sobrenome do primeiro autor da referência em caixa alta,
    tratando corretamente entidades corporativas e autores múltiplos.
  -->
  <xsl:template name="obter-sobrenome-referencia">
    <xsl:param name="ref-id"/>
    <xsl:variable name="ref" select="//referencia[@id=$ref-id]"/>

    <xsl:choose>
      <!-- Autor pessoa física — sobrenome -->
      <xsl:when test="$ref/autores/autor[1]/sobrenome">
        <xsl:call-template name="formatar-sobrenome-citacao">
          <xsl:with-param name="sobrenome"
                          select="$ref/autores/autor[1]/sobrenome"/>
        </xsl:call-template>
      </xsl:when>

      <!-- Autor corporativo — nome da instituição em caixa alta -->
      <xsl:when test="$ref/autor-corporativo">
        <xsl:call-template name="formatar-sobrenome-citacao">
          <xsl:with-param name="sobrenome" select="$ref/autor-corporativo"/>
        </xsl:call-template>
      </xsl:when>

      <!-- Entrada pelo título (obras sem autoria identificada) -->
      <xsl:when test="$ref/titulo">
        <!-- Primeira palavra em caixa alta conforme NBR 10520:2023 -->
        <xsl:call-template name="formatar-sobrenome-citacao">
          <xsl:with-param name="sobrenome"
                          select="substring-before(concat($ref/titulo,' '),' ')"/>
        </xsl:call-template>
        <xsl:text>&#8230;</xsl:text>
        <!-- &#8230; = reticências … -->
      </xsl:when>

      <!-- Fallback — usa o ID como identificador -->
      <xsl:otherwise>
        <xsl:value-of select="$ref-id"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--
    Retorna o ano de publicação da referência, com marcador [s.d.]
    quando não há data identificada.
  -->
  <xsl:template name="obter-ano-referencia">
    <xsl:param name="ref-id"/>
    <xsl:variable name="ref" select="//referencia[@id=$ref-id]"/>

    <xsl:choose>
      <xsl:when test="$ref/ano">
        <xsl:value-of select="$ref/ano"/>
      </xsl:when>
      <xsl:when test="$ref/data/ano">
        <xsl:value-of select="$ref/data/ano"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$marcador-sem-data"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--
    Formata a indicação de localização (página ou páginas) na chamada.
    Gera: ", p. X" ou ", p. X-Y" conforme o caso.
    A indicação é opcional nas citações indiretas (NBR 10520:2023 §5.4).
  -->
  <xsl:template name="formatar-localizacao-pagina">
    <xsl:param name="pagina"/>
    <xsl:param name="paginas"/>

    <xsl:choose>
      <xsl:when test="$pagina and $pagina != ''">
        <xsl:text>, </xsl:text>
        <xsl:value-of select="$marcador-pagina"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="$pagina"/>
      </xsl:when>
      <xsl:when test="$paginas and $paginas != ''">
        <xsl:text>, </xsl:text>
        <xsl:value-of select="$marcador-paginas-plural"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="$paginas"/>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <!--
    Converte uma string para caixa alta usando translate().
    Abrange o conjunto de caracteres do português brasileiro.
    Limitação do XSLT 1.0: não suporta Unicode completo via translate().
  -->
  <xsl:template name="formatar-sobrenome-citacao">
    <xsl:param name="sobrenome"/>
    <span class="sobrenome-autor">
      <xsl:value-of select="translate(
        $sobrenome,
        'abcdefghijklmnopqrstuvwxyzàáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿ',
        'ABCDEFGHIJKLMNOPQRSTUVWXYZÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞŸ'
      )"/>
    </span>
  </xsl:template>

  <!--
    Constrói texto acessível descritivo da chamada para leitores de tela,
    sem formatação visual. Usado em atributos aria-label e figcaption.
  -->
  <xsl:template name="texto-chamada-acessivel">
    <xsl:param name="ref-id"/>
    <xsl:param name="pagina"/>
    <xsl:param name="paginas"/>
    <xsl:variable name="ref" select="//referencia[@id=$ref-id]"/>
    <xsl:choose>
      <xsl:when test="$ref/autores/autor[1]/sobrenome">
        <xsl:value-of select="$ref/autores/autor[1]/sobrenome"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$ref-id"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>, </xsl:text>
    <xsl:call-template name="obter-ano-referencia">
      <xsl:with-param name="ref-id" select="$ref-id"/>
    </xsl:call-template>
    <xsl:if test="$pagina">
      <xsl:text>, página </xsl:text>
      <xsl:value-of select="$pagina"/>
    </xsl:if>
  </xsl:template>


  <!-- ═══════════════════════════════════════════════════════════════════════
       SEÇÃO 13 — LISTA DE REFERÊNCIAS BIBLIOGRÁFICAS
       NBR 10520:2023 §8 + NBR 6023:2018 — formatação das entradas.
       ═══════════════════════════════════════════════════════════════════════ -->

  <!--
    Renderiza a seção completa de referências, com título em caixa alta,
    centralizado (se configurado) e alinhamento à esquerda das entradas.
    NBR 10520:2023 §8.1 — referências ordenadas alfabeticamente (autor-data)
    ou numericamente (sistema numérico).
  -->
  <xsl:template name="renderizar-secao-referencias">
    <h2 class="titulo-referencias">
      <xsl:value-of select="$titulo-referencias"/>
    </h2>

    <div class="lista-referencias" role="list">
      <xsl:choose>

        <!-- Sistema numérico: ordenar pela ordem de aparecimento no texto -->
        <xsl:when test="$sistema-citacao = 'numerico'">
          <xsl:apply-templates select="referencias/referencia"
                               mode="referencia-numerica">
            <xsl:sort select="@id" data-type="text" order="ascending"/>
          </xsl:apply-templates>
        </xsl:when>

        <!-- Sistema autor-data: ordenar alfabeticamente pelo sobrenome -->
        <xsl:otherwise>
          <xsl:apply-templates select="referencias/referencia"
                               mode="referencia-autor-data">
            <xsl:sort select="autores/autor[1]/sobrenome |
                              autor-corporativo"
                      data-type="text"
                      order="ascending"/>
          </xsl:apply-templates>
        </xsl:otherwise>

      </xsl:choose>
    </div>
  </xsl:template>

  <!--
    Renderiza uma entrada de referência no sistema AUTOR-DATA.
    O processamento é delegado a templates específicos por tipo de documento
    conforme NBR 6023:2018 (monografia, artigo, capítulo, tese, site etc.).
  -->
  <xsl:template match="referencia" mode="referencia-autor-data">
    <div class="referencia"
         id="ref-{@id}"
         role="listitem"
         data-tipo="{@tipo}">
      <xsl:call-template name="formatar-referencia"/>
    </div>
  </xsl:template>

  <xsl:template match="referencia" mode="referencia-numerica">
    <div class="referencia referencia-numerica"
         id="ref-{@id}"
         role="listitem"
         data-tipo="{@tipo}">
      <xsl:call-template name="formatar-referencia"/>
    </div>
  </xsl:template>

  <!--
    Dispatcher: roteia o processamento para o template adequado
    conforme o atributo @tipo da referência.
  -->
  <xsl:template name="formatar-referencia">
    <xsl:choose>
      <xsl:when test="@tipo = 'livro' or @tipo = 'monografia' or not(@tipo)">
        <xsl:call-template name="ref-livro"/>
      </xsl:when>
      <xsl:when test="@tipo = 'artigo' or @tipo = 'artigo-periodico'">
        <xsl:call-template name="ref-artigo-periodico"/>
      </xsl:when>
      <xsl:when test="@tipo = 'capitulo' or @tipo = 'parte'">
        <xsl:call-template name="ref-capitulo-livro"/>
      </xsl:when>
      <xsl:when test="@tipo = 'tese' or @tipo = 'dissertacao'
                      or @tipo = 'tcc' or @tipo = 'trabalho-academico'">
        <xsl:call-template name="ref-trabalho-academico"/>
      </xsl:when>
      <xsl:when test="@tipo = 'site' or @tipo = 'pagina-web'
                      or @tipo = 'documento-eletronico'">
        <xsl:call-template name="ref-documento-eletronico"/>
      </xsl:when>
      <xsl:when test="@tipo = 'legislacao' or @tipo = 'norma'">
        <xsl:call-template name="ref-legislacao"/>
      </xsl:when>
      <xsl:when test="@tipo = 'evento' or @tipo = 'conferencia'
                      or @tipo = 'congresso'">
        <xsl:call-template name="ref-evento"/>
      </xsl:when>
      <xsl:otherwise>
        <!-- Tipo desconhecido: renderização genérica -->
        <xsl:call-template name="ref-generica"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- ───────────────────────────────────────────────────────────────────────
       13.1 — REFERÊNCIA: LIVRO / MONOGRAFIA
       NBR 6023:2018 §7.2
       Formato: SOBRENOME, Nome. Título: subtítulo. Ed. Local: Editora, ano.
       ─────────────────────────────────────────────────────────────────────── -->
  <xsl:template name="ref-livro">
    <!-- Autoria -->
    <xsl:call-template name="formatar-autoria"/>
    <!-- Título em negrito -->
    <xsl:text> </xsl:text>
    <strong class="titulo-obra">
      <xsl:value-of select="titulo"/>
    </strong>
    <!-- Subtítulo após dois pontos, sem negrito -->
    <xsl:if test="subtitulo">
      <xsl:text>: </xsl:text>
      <span class="subtitulo-obra">
        <xsl:value-of select="subtitulo"/>
      </span>
    </xsl:if>
    <!-- Edição, quando não for a primeira -->
    <xsl:if test="edicao">
      <xsl:text>. </xsl:text>
      <xsl:value-of select="edicao"/>
      <xsl:text>. ed.</xsl:text>
    </xsl:if>
    <!-- Local de publicação -->
    <xsl:text>. </xsl:text>
    <xsl:choose>
      <xsl:when test="local">
        <xsl:value-of select="local"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$marcador-sem-local"/>
      </xsl:otherwise>
    </xsl:choose>
    <!-- Editora -->
    <xsl:text>: </xsl:text>
    <xsl:choose>
      <xsl:when test="editora">
        <xsl:value-of select="editora"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$marcador-sem-editora"/>
      </xsl:otherwise>
    </xsl:choose>
    <!-- Ano -->
    <xsl:text>, </xsl:text>
    <xsl:choose>
      <xsl:when test="ano">
        <xsl:value-of select="ano"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$marcador-sem-data"/>
      </xsl:otherwise>
    </xsl:choose>
    <!-- Total de páginas, se disponível -->
    <xsl:if test="total-paginas">
      <xsl:text>. </xsl:text>
      <xsl:value-of select="total-paginas"/>
      <xsl:text> p.</xsl:text>
    </xsl:if>
    <!-- Série ou coleção -->
    <xsl:if test="serie">
      <xsl:text>. (</xsl:text>
      <xsl:value-of select="serie"/>
      <xsl:text>)</xsl:text>
    </xsl:if>
    <!-- ISBN -->
    <xsl:if test="isbn">
      <xsl:text>. ISBN </xsl:text>
      <xsl:value-of select="isbn"/>
    </xsl:if>
    <xsl:text>.</xsl:text>
  </xsl:template>

  <!-- ───────────────────────────────────────────────────────────────────────
       13.2 — REFERÊNCIA: ARTIGO DE PERIÓDICO
       NBR 6023:2018 §7.5
       Formato: AUTOR. Título. Nome do periódico, local, v. X, n. Y, p. Z, ano.
       ─────────────────────────────────────────────────────────────────────── -->
  <xsl:template name="ref-artigo-periodico">
    <!-- Autoria -->
    <xsl:call-template name="formatar-autoria"/>
    <!-- Título do artigo sem destaque (sem negrito) conforme NBR 6023:2018 -->
    <xsl:text> </xsl:text>
    <span class="titulo-artigo">
      <xsl:value-of select="titulo"/>
    </span>
    <xsl:if test="subtitulo">
      <xsl:text>: </xsl:text>
      <xsl:value-of select="subtitulo"/>
    </xsl:if>
    <!-- Nome do periódico em negrito -->
    <xsl:text>. </xsl:text>
    <strong class="nome-periodico">
      <xsl:value-of select="periodico/nome | nome-periodico"/>
    </strong>
    <!-- Local de publicação do periódico -->
    <xsl:if test="periodico/local | local">
      <xsl:text>, </xsl:text>
      <xsl:value-of select="periodico/local | local"/>
    </xsl:if>
    <!-- Volume -->
    <xsl:if test="volume">
      <xsl:text>, v. </xsl:text>
      <xsl:value-of select="volume"/>
    </xsl:if>
    <!-- Número/fascículo -->
    <xsl:if test="numero">
      <xsl:text>, n. </xsl:text>
      <xsl:value-of select="numero"/>
    </xsl:if>
    <!-- Páginas do artigo -->
    <xsl:if test="paginas">
      <xsl:text>, </xsl:text>
      <xsl:value-of select="$marcador-paginas-plural"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="paginas"/>
    </xsl:if>
    <!-- Ano de publicação -->
    <xsl:text>, </xsl:text>
    <xsl:choose>
      <xsl:when test="ano">
        <xsl:value-of select="ano"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$marcador-sem-data"/>
      </xsl:otherwise>
    </xsl:choose>
    <!-- DOI -->
    <xsl:if test="doi">
      <xsl:text>. DOI: </xsl:text>
      <a href="https://doi.org/{doi}" class="doi-link" target="_blank"
         rel="noopener noreferrer">
        <xsl:value-of select="doi"/>
      </a>
    </xsl:if>
    <!-- ISSN -->
    <xsl:if test="issn">
      <xsl:text>. ISSN </xsl:text>
      <xsl:value-of select="issn"/>
    </xsl:if>
    <!-- Disponibilidade (acesso online) -->
    <xsl:if test="url">
      <xsl:text>. Disponível em: </xsl:text>
      <a href="{url}" class="url-referencia" target="_blank"
         rel="noopener noreferrer">
        <xsl:value-of select="url"/>
      </a>
      <xsl:if test="data-acesso">
        <xsl:text>. Acesso em: </xsl:text>
        <xsl:call-template name="formatar-data-acesso">
          <xsl:with-param name="data" select="data-acesso"/>
        </xsl:call-template>
      </xsl:if>
    </xsl:if>
    <xsl:text>.</xsl:text>
  </xsl:template>

  <!-- ───────────────────────────────────────────────────────────────────────
       13.3 — REFERÊNCIA: CAPÍTULO DE LIVRO / PARTE DE DOCUMENTO
       NBR 6023:2018 §7.3
       Formato: AUTOR DO CAP. Título do capítulo. In: AUTOR(ES) DO LIVRO.
                Título do livro. Local: Editora, ano. p. X-Y.
       ─────────────────────────────────────────────────────────────────────── -->
  <xsl:template name="ref-capitulo-livro">
    <!-- Autoria do capítulo -->
    <xsl:call-template name="formatar-autoria"/>
    <!-- Título do capítulo -->
    <xsl:text> </xsl:text>
    <span class="titulo-capitulo">
      <xsl:value-of select="titulo"/>
    </span>
    <xsl:if test="subtitulo">
      <xsl:text>: </xsl:text>
      <xsl:value-of select="subtitulo"/>
    </xsl:if>
    <!-- Conectivo "In:" -->
    <xsl:text>. In: </xsl:text>
    <!-- Autores do livro hospedeiro -->
    <xsl:if test="livro/autores | obra-completa/autores">
      <xsl:call-template name="formatar-autoria-hospedeira"/>
      <xsl:text>. </xsl:text>
    </xsl:if>
    <!-- Título da obra completa em negrito -->
    <strong class="titulo-obra-hospedeira">
      <xsl:value-of select="livro/titulo | obra-completa/titulo"/>
    </strong>
    <xsl:if test="livro/subtitulo | obra-completa/subtitulo">
      <xsl:text>: </xsl:text>
      <xsl:value-of select="livro/subtitulo | obra-completa/subtitulo"/>
    </xsl:if>
    <!-- Edição da obra completa -->
    <xsl:if test="livro/edicao | obra-completa/edicao">
      <xsl:text>. </xsl:text>
      <xsl:value-of select="livro/edicao | obra-completa/edicao"/>
      <xsl:text>. ed.</xsl:text>
    </xsl:if>
    <!-- Local -->
    <xsl:text>. </xsl:text>
    <xsl:value-of select="livro/local | obra-completa/local | $marcador-sem-local"/>
    <!-- Editora -->
    <xsl:text>: </xsl:text>
    <xsl:value-of select="livro/editora | obra-completa/editora | $marcador-sem-editora"/>
    <!-- Ano -->
    <xsl:text>, </xsl:text>
    <xsl:value-of select="livro/ano | obra-completa/ano | ano | $marcador-sem-data"/>
    <!-- Páginas do capítulo na obra -->
    <xsl:if test="paginas">
      <xsl:text>. </xsl:text>
      <xsl:value-of select="$marcador-paginas-plural"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="paginas"/>
    </xsl:if>
    <xsl:text>.</xsl:text>
  </xsl:template>

  <!-- ───────────────────────────────────────────────────────────────────────
       13.4 — REFERÊNCIA: TRABALHO ACADÊMICO (TESE, DISSERTAÇÃO, TCC)
       NBR 6023:2018 §7.8
       Formato: AUTOR. Título. Ano. Tipo. (Grau — Programa) — Instituição, Local.
       ─────────────────────────────────────────────────────────────────────── -->
  <xsl:template name="ref-trabalho-academico">
    <!-- Autoria -->
    <xsl:call-template name="formatar-autoria"/>
    <!-- Título em negrito -->
    <xsl:text> </xsl:text>
    <strong class="titulo-obra">
      <xsl:value-of select="titulo"/>
    </strong>
    <xsl:if test="subtitulo">
      <xsl:text>: </xsl:text>
      <xsl:value-of select="subtitulo"/>
    </xsl:if>
    <!-- Ano de defesa -->
    <xsl:text>. </xsl:text>
    <xsl:value-of select="ano | $marcador-sem-data"/>
    <!-- Tipo de trabalho e grau -->
    <xsl:text>. </xsl:text>
    <span class="tipo-trabalho">
      <xsl:choose>
        <xsl:when test="@tipo = 'tese'">Tese (Doutorado</xsl:when>
        <xsl:when test="@tipo = 'dissertacao'">Dissertação (Mestrado</xsl:when>
        <xsl:when test="@tipo = 'tcc'">Trabalho de Conclusão de Curso</xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="tipo-trabalho"/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:if test="programa">
        <xsl:text> em </xsl:text>
        <xsl:value-of select="programa"/>
      </xsl:if>
      <xsl:if test="@tipo = 'tese' or @tipo = 'dissertacao'">
        <xsl:text>)</xsl:text>
      </xsl:if>
    </span>
    <!-- Instituição e local -->
    <xsl:text> — </xsl:text>
    <xsl:value-of select="instituicao"/>
    <xsl:if test="local">
      <xsl:text>, </xsl:text>
      <xsl:value-of select="local"/>
    </xsl:if>
    <xsl:text>.</xsl:text>
    <!-- URL para repositório institucional -->
    <xsl:if test="url">
      <xsl:text> Disponível em: </xsl:text>
      <a href="{url}" class="url-referencia" target="_blank"
         rel="noopener noreferrer">
        <xsl:value-of select="url"/>
      </a>
      <xsl:if test="data-acesso">
        <xsl:text>. Acesso em: </xsl:text>
        <xsl:call-template name="formatar-data-acesso">
          <xsl:with-param name="data" select="data-acesso"/>
        </xsl:call-template>
      </xsl:if>
      <xsl:text>.</xsl:text>
    </xsl:if>
  </xsl:template>

  <!-- ───────────────────────────────────────────────────────────────────────
       13.5 — REFERÊNCIA: DOCUMENTO ELETRÔNICO / PÁGINA WEB
       NBR 6023:2018 §7.11
       Inclui: acesso em: dia mês. ano (obrigatório para conteúdo dinâmico).
       ─────────────────────────────────────────────────────────────────────── -->
  <xsl:template name="ref-documento-eletronico">
    <!-- Autoria (pessoa ou organização) -->
    <xsl:call-template name="formatar-autoria"/>
    <!-- Título do documento em negrito -->
    <xsl:text> </xsl:text>
    <strong class="titulo-obra">
      <xsl:value-of select="titulo"/>
    </strong>
    <xsl:if test="subtitulo">
      <xsl:text>: </xsl:text>
      <xsl:value-of select="subtitulo"/>
    </xsl:if>
    <!-- Local/ano quando disponíveis -->
    <xsl:if test="local">
      <xsl:text>. </xsl:text>
      <xsl:value-of select="local"/>
    </xsl:if>
    <xsl:if test="ano">
      <xsl:text>, </xsl:text>
      <xsl:value-of select="ano"/>
    </xsl:if>
    <!-- URL — obrigatória para documentos eletrônicos -->
    <xsl:text>. Disponível em: </xsl:text>
    <a href="{url}" class="url-referencia" target="_blank"
       rel="noopener noreferrer">
      <xsl:value-of select="url"/>
    </a>
    <!-- Data de acesso — obrigatória conforme NBR 6023:2018 §7.11 -->
    <xsl:text>. Acesso em: </xsl:text>
    <xsl:choose>
      <xsl:when test="data-acesso">
        <xsl:call-template name="formatar-data-acesso">
          <xsl:with-param name="data" select="data-acesso"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <span class="dado-ausente">[data de acesso não informada]</span>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>.</xsl:text>
  </xsl:template>

  <!-- ───────────────────────────────────────────────────────────────────────
       13.6 — REFERÊNCIA: LEGISLAÇÃO E NORMAS TÉCNICAS
       NBR 6023:2018 §7.9 e §7.10
       ─────────────────────────────────────────────────────────────────────── -->
  <xsl:template name="ref-legislacao">
    <!-- Jurisdição / Entidade normalizadora -->
    <xsl:if test="jurisdicao | entidade">
      <span class="jurisdicao">
        <xsl:value-of select="translate(
          jurisdicao | entidade,
          'abcdefghijklmnopqrstuvwxyz',
          'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
        )"/>
      </span>
      <xsl:text>. </xsl:text>
    </xsl:if>
    <!-- Título/Ementa em negrito -->
    <strong class="titulo-legislacao">
      <xsl:value-of select="titulo"/>
    </strong>
    <xsl:if test="subtitulo">
      <xsl:text>: </xsl:text>
      <xsl:value-of select="subtitulo"/>
    </xsl:if>
    <!-- Número, data e ementa -->
    <xsl:if test="numero">
      <xsl:text>. </xsl:text>
      <xsl:value-of select="numero"/>
    </xsl:if>
    <xsl:if test="ementa">
      <xsl:text>. </xsl:text>
      <xsl:value-of select="ementa"/>
    </xsl:if>
    <!-- Diário Oficial / Publicação -->
    <xsl:if test="publicacao">
      <xsl:text>. </xsl:text>
      <xsl:value-of select="publicacao"/>
    </xsl:if>
    <!-- Localização na publicação oficial -->
    <xsl:if test="local">
      <xsl:text>, </xsl:text>
      <xsl:value-of select="local"/>
    </xsl:if>
    <xsl:if test="data-publicacao | ano">
      <xsl:text>, </xsl:text>
      <xsl:value-of select="data-publicacao | ano"/>
    </xsl:if>
    <xsl:if test="secao">
      <xsl:text>. Seção </xsl:text>
      <xsl:value-of select="secao"/>
    </xsl:if>
    <xsl:if test="paginas">
      <xsl:text>, </xsl:text>
      <xsl:value-of select="$marcador-paginas-plural"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="paginas"/>
    </xsl:if>
    <!-- URL opcional para versão eletrônica *)-->
    <xsl:if test="url">
      <xsl:text>. Disponível em: </xsl:text>
      <a href="{url}" class="url-referencia" target="_blank"
         rel="noopener noreferrer">
        <xsl:value-of select="url"/>
      </a>
      <xsl:if test="data-acesso">
        <xsl:text>. Acesso em: </xsl:text>
        <xsl:call-template name="formatar-data-acesso">
          <xsl:with-param name="data" select="data-acesso"/>
        </xsl:call-template>
      </xsl:if>
    </xsl:if>
    <xsl:text>.</xsl:text>
  </xsl:template>

  <!-- ───────────────────────────────────────────────────────────────────────
       13.7 — REFERÊNCIA: TRABALHO EM EVENTO (ANAIS, CONGRESSO, SIMPÓSIO)
       NBR 6023:2018 §7.6
       ─────────────────────────────────────────────────────────────────────── -->
  <xsl:template name="ref-evento">
    <!-- Autoria -->
    <xsl:call-template name="formatar-autoria"/>
    <!-- Título do trabalho -->
    <xsl:text> </xsl:text>
    <span class="titulo-trabalho-evento">
      <xsl:value-of select="titulo"/>
    </span>
    <!-- Conectivo "In:" e nome do evento em caixa alta -->
    <xsl:text>. In: </xsl:text>
    <strong class="nome-evento">
      <xsl:value-of select="translate(
        evento/nome | nome-evento,
        'abcdefghijklmnopqrstuvwxyz',
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
      )"/>
    </strong>
    <!-- Número do evento -->
    <xsl:if test="evento/numero | numero-evento">
      <xsl:text>, </xsl:text>
      <xsl:value-of select="evento/numero | numero-evento"/>
      <xsl:text>.</xsl:text>
    </xsl:if>
    <!-- Ano de realização -->
    <xsl:text>, </xsl:text>
    <xsl:value-of select="evento/ano | ano | $marcador-sem-data"/>
    <!-- Local de realização -->
    <xsl:if test="evento/local | local-evento">
      <xsl:text>, </xsl:text>
      <xsl:value-of select="evento/local | local-evento"/>
    </xsl:if>
    <!-- Tipo de publicação (Anais, Proceedings etc.) -->
    <xsl:text>. </xsl:text>
    <strong class="titulo-anais">
      <xsl:choose>
        <xsl:when test="publicacao/titulo | anais/titulo">
          <xsl:value-of select="publicacao/titulo | anais/titulo"/>
        </xsl:when>
        <xsl:otherwise>Anais [...]</xsl:otherwise>
      </xsl:choose>
    </strong>
    <!-- Local e ano da publicação dos anais -->
    <xsl:if test="publicacao/local | anais/local">
      <xsl:text>. </xsl:text>
      <xsl:value-of select="publicacao/local | anais/local"/>
    </xsl:if>
    <xsl:if test="publicacao/editora | anais/editora">
      <xsl:text>: </xsl:text>
      <xsl:value-of select="publicacao/editora | anais/editora"/>
    </xsl:if>
    <xsl:if test="publicacao/ano | anais/ano">
      <xsl:text>, </xsl:text>
      <xsl:value-of select="publicacao/ano | anais/ano"/>
    </xsl:if>
    <!-- Páginas do trabalho nos anais -->
    <xsl:if test="paginas">
      <xsl:text>. </xsl:text>
      <xsl:value-of select="$marcador-paginas-plural"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="paginas"/>
    </xsl:if>
    <xsl:text>.</xsl:text>
  </xsl:template>

  <!-- ───────────────────────────────────────────────────────────────────────
       13.8 — REFERÊNCIA: FORMATO GENÉRICO (fallback)
       Garante que todas as referências sejam renderizadas mesmo sem tipo.
       ─────────────────────────────────────────────────────────────────────── -->
  <xsl:template name="ref-generica">
    <xsl:call-template name="formatar-autoria"/>
    <xsl:text> </xsl:text>
    <strong class="titulo-obra"><xsl:value-of select="titulo"/></strong>
    <xsl:if test="local"><xsl:text>. </xsl:text><xsl:value-of select="local"/></xsl:if>
    <xsl:if test="editora"><xsl:text>: </xsl:text><xsl:value-of select="editora"/></xsl:if>
    <xsl:if test="ano"><xsl:text>, </xsl:text><xsl:value-of select="ano"/></xsl:if>
    <xsl:text>.</xsl:text>
  </xsl:template>


  <!-- ═══════════════════════════════════════════════════════════════════════
       SEÇÃO 14 — FORMATAÇÃO DE AUTORIA NAS REFERÊNCIAS
       NBR 6023:2018 §4 — regras para apresentação de autores.
       ═══════════════════════════════════════════════════════════════════════ -->

  <!--
    Formata a lista de autores conforme NBR 6023:2018 §4.1:
      — Um autor:   SOBRENOME, Nome.
      — Dois:       SOBRENOME1, Nome1; SOBRENOME2, Nome2.
      — Três:       SOBRENOME1, Nome1; SOBRENOME2, Nome2; SOBRENOME3, Nome3.
      — Quatro+:    SOBRENOME1, Nome1 et al.
      — Corporativo: NOME DA INSTITUIÇÃO.
  -->
  <xsl:template name="formatar-autoria">
    <span class="autoria">
      <xsl:choose>

        <!-- Autor corporativo (instituição, organização) -->
        <xsl:when test="autor-corporativo">
          <span class="autor-corporativo">
            <xsl:value-of select="translate(
              autor-corporativo,
              'abcdefghijklmnopqrstuvwxyz',
              'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
            )"/>
          </span>
        </xsl:when>

        <!-- Quatro ou mais autores: apenas o primeiro + et al. -->
        <xsl:when test="count(autores/autor) &gt; 3">
          <xsl:call-template name="formatar-autor-individual">
            <xsl:with-param name="autor" select="autores/autor[1]"/>
          </xsl:call-template>
          <xsl:text> </xsl:text>
          <em class="et-al"><xsl:value-of select="$prefixo-et-al"/></em>
        </xsl:when>

        <!-- Um, dois ou três autores: todos listados com ponto-e-vírgula -->
        <xsl:otherwise>
          <xsl:for-each select="autores/autor">
            <xsl:if test="position() &gt; 1">
              <xsl:text>; </xsl:text>
            </xsl:if>
            <xsl:call-template name="formatar-autor-individual">
              <xsl:with-param name="autor" select="."/>
            </xsl:call-template>
          </xsl:for-each>
        </xsl:otherwise>

      </xsl:choose>
    </span>
    <xsl:text>.</xsl:text>
  </xsl:template>

  <!--
    Formata um único autor na forma SOBRENOME, Nome.
    Trata: sobrenome simples, sobrenome composto, prenome abreviado.
  -->
  <xsl:template name="formatar-autor-individual">
    <xsl:param name="autor"/>
    <span class="autor-individual">
      <!-- Sobrenome em MAIÚSCULAS -->
      <span class="sobrenome-referencia">
        <xsl:value-of select="translate(
          $autor/sobrenome,
          'abcdefghijklmnopqrstuvwxyz',
          'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
        )"/>
      </span>
      <!-- Vírgula separadora -->
      <xsl:text>, </xsl:text>
      <!-- Prenome(s) por extenso ou abreviado conforme o documento fonte -->
      <span class="prenome-referencia">
        <xsl:choose>
          <xsl:when test="$autor/prenome">
            <xsl:value-of select="$autor/prenome"/>
          </xsl:when>
          <xsl:when test="$autor/nome">
            <!-- Se vier como elemento único <nome>, extrair sobrenome automaticamente -->
            <xsl:value-of select="$autor/nome"/>
          </xsl:when>
        </xsl:choose>
      </span>
    </span>
  </xsl:template>

  <!--
    Formata autoria da obra hospedeira (para capítulos de livro).
    Reutiliza a mesma lógica, mas para o nó <livro> ou <obra-completa>.
  -->
  <xsl:template name="formatar-autoria-hospedeira">
    <xsl:for-each select="livro/autores/autor | obra-completa/autores/autor">
      <xsl:if test="position() &gt; 1">
        <xsl:text>; </xsl:text>
      </xsl:if>
      <xsl:call-template name="formatar-autor-individual">
        <xsl:with-param name="autor" select="."/>
      </xsl:call-template>
    </xsl:for-each>
    <xsl:if test="livro/autor-corporativo | obra-completa/autor-corporativo">
      <xsl:value-of select="translate(
        livro/autor-corporativo | obra-completa/autor-corporativo,
        'abcdefghijklmnopqrstuvwxyz',
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
      )"/>
    </xsl:if>
  </xsl:template>

  <!--
    Formata a data de acesso no padrão ABNT: "dia mês. ano"
    Ex: "15 mar. 2024" — mês em minúsculo e abreviado com ponto.
    Entrada esperada: ISO 8601 "AAAA-MM-DD" ou "DD/MM/AAAA".
  -->
  <xsl:template name="formatar-data-acesso">
    <xsl:param name="data"/>

    <xsl:variable name="meses"
      select="'jan.fev.mar.abr.mai.jun.jul.ago.set.out.nov.dez.'"/>

    <!-- Tenta interpretar formato ISO 8601: AAAA-MM-DD -->
    <xsl:variable name="ano-iso"  select="substring($data, 1, 4)"/>
    <xsl:variable name="mes-iso"  select="substring($data, 6, 2)"/>
    <xsl:variable name="dia-iso"  select="substring($data, 9, 2)"/>

    <xsl:choose>
      <!-- Formato ISO detectado -->
      <xsl:when test="string-length($data) = 10 and substring($data, 5, 1) = '-'">
        <span class="data-acesso">
          <xsl:value-of select="number($dia-iso)"/>
          <xsl:text> </xsl:text>
          <!-- Extrai o mês abreviado do mapeamento manual *)-->
          <xsl:variable name="pos-mes" select="(number($mes-iso) - 1) * 4 + 1"/>
          <xsl:value-of select="substring($meses, $pos-mes, 4)"/>
          <xsl:text> </xsl:text>
          <xsl:value-of select="$ano-iso"/>
        </span>
      </xsl:when>

      <!-- Formato não reconhecido: exibe como está -->
      <xsl:otherwise>
        <span class="data-acesso">
          <xsl:value-of select="$data"/>
        </span>
      </xsl:otherwise>
    </xsl:choose>
  </xtml:template>


  <!-- ═══════════════════════════════════════════════════════════════════════
       SEÇÃO 15 — ESTILOS CSS INLINE
       Formatação tipográfica conforme NBR 10520:2023 e NBR 14724:2011.
       Baseado em: Times New Roman 12pt, espaçamento 1,5 linhas, margens ABNT.
       ═══════════════════════════════════════════════════════════════════════ -->

  <xsl:template name="estilos-css">
    <xsl:text>
/* ═══════════════════════════════════════════════════════════════════════
   RESET E BASE TIPOGRÁFICA — ABNT NBR 14724:2011 + NBR 10520:2023
   ═══════════════════════════════════════════════════════════════════════ */

*, *::before, *::after {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

:root {
  /* Variáveis de design ABNT */
  --fonte-principal:       "Times New Roman", Times, Georgia, serif;
  --fonte-codigo:          "Courier New", Courier, monospace;
  --tamanho-corpo:         12pt;
  --tamanho-citacao-longa: </xsl:text>
    <xsl:value-of select="$tamanho-fonte-citacao-longa"/>
    <xsl:text>;
  --espacamento-linha:     1.5;
  --espacamento-simples:   </xsl:text>
    <xsl:value-of select="$espacamento-simples"/>
    <xsl:text>;
  --recuo-citacao-longa:   </xsl:text>
    <xsl:value-of select="$recuo-citacao-longa"/>
    <xsl:text>;
  --recuo-paragrafo:       1.25cm;
  --margem-superior:       3cm;
  --margem-inferior:       2cm;
  --margem-esquerda:       3cm;
  --margem-direita:        2cm;
  --largura-maxima:        21cm;
  --cor-texto:             #1a1a1a;
  --cor-destaque:          #003366;
  --cor-link:              #0056b3;
  --cor-link-hover:        #003d80;
  --cor-borda-citacao:     #555555;
  --cor-fundo-citacao:     #f9f9f9;
  --cor-erro:              #cc0000;
  --cor-aviso:             #996600;
}

html {
  font-size: var(--tamanho-corpo);
  scroll-behavior: smooth;
}

body {
  font-family:   var(--fonte-principal);
  font-size:     var(--tamanho-corpo);
  line-height:   var(--espacamento-linha);
  color:         var(--cor-texto);
  background:    #ffffff;
  /* Simulação de margens ABNT para visualização em tela */
  max-width:     var(--largura-maxima);
  margin:        0 auto;
  padding:       var(--margem-superior)
                 var(--margem-direita)
                 var(--margem-inferior)
                 var(--margem-esquerda);
}

/* ═══════════════════════════════════════════════════════════════════════
   TIPOGRAFIA — HIERARQUIA DE TÍTULOS E HEADINGS
   ═══════════════════════════════════════════════════════════════════════ */

h1, h2, h3, h4, h5, h6 {
  font-family:   var(--fonte-principal);
  font-weight:   bold;
  text-transform: uppercase;
  color:         var(--cor-texto);
  margin-top:    1.5em;
  margin-bottom: 0.5em;
}

h1.titulo-documento {
  font-size:   14pt;
  text-align:  center;
  margin:      2em auto 0.5em;
  line-height: 1.3;
}

h2.titulo-secao,
h2.titulo-referencias {
  font-size:   12pt;
  text-align:  center;
  border-bottom: none;
  margin-top:  2em;
}

h3.titulo-subsecao {
  font-size:   12pt;
  text-align:  left;
}

h4.titulo-subsubsecao {
  font-size:   12pt;
  text-align:  left;
  font-style:  italic;
}

/* ═══════════════════════════════════════════════════════════════════════
   PARÁGRAFOS E FLUXO DE TEXTO
   ═══════════════════════════════════════════════════════════════════════ */

p.paragrafo {
  text-indent:   var(--recuo-paragrafo);
  text-align:    justify;
  margin-bottom: 0;
  line-height:   var(--espacamento-linha);
}

/* Primeiro parágrafo após título: sem recuo conforme NBR 14724 *)*/
h2 + p.paragrafo,
h3 + p.paragrafo,
h4 + p.paragrafo {
  text-indent: 0;
}

/* ═══════════════════════════════════════════════════════════════════════
   CITAÇÃO DIRETA CURTA — NBR 10520:2023 §5.2
   Entre aspas no próprio corpo do texto, sem recuo especial.
   ═══════════════════════════════════════════════════════════════════════ */

span.citacao-direta-curta {
  display:     inline;
}

span.citacao-direta-curta q.texto-citado {
  quotes:     "\201C" "\201D" "\2018" "\2019";
  font-style: normal;
}

span.citacao-direta-curta q.texto-citado::before {
  content: open-quote;
}

span.citacao-direta-curta q.texto-citado::after {
  content: close-quote;
}

/* ═══════════════════════════════════════════════════════════════════════
   CITAÇÃO DIRETA LONGA — NBR 10520:2023 §5.3
   Parágrafo próprio, recuo 4cm, fonte menor, espaço simples, sem aspas.
   ═══════════════════════════════════════════════════════════════════════ */

figure.citacao-direta-longa-container {
  margin: 1.5em 0;
}

blockquote.citacao-direta-longa {
  display:      block;
  margin-left:  var(--recuo-citacao-longa);
  margin-right: 0;
  margin-top:   1em;
  margin-bottom:1em;
  font-size:    var(--tamanho-citacao-longa);
  line-height:  var(--espacamento-simples);
  text-align:   justify;
  font-style:   normal;
  color:        var(--cor-texto);
  background:   transparent;
  border:       none;
  padding:      0;
}

blockquote.citacao-direta-longa footer.chamada-bibliografica-longa {
  text-align:   right;
  margin-top:   0.25em;
  font-size:    var(--tamanho-citacao-longa);
}

/* ═══════════════════════════════════════════════════════════════════════
   CHAMADAS BIBLIOGRÁFICAS (AUTOR-DATA)
   ═══════════════════════════════════════════════════════════════════════ */

span.chamada-bibliografica {
  white-space: nowrap;
}

span.sobrenome-autor {
  font-weight: normal;
  text-transform: uppercase;
}

em.apud-termo {
  font-style: italic;
}

em.et-al {
  font-style: italic;
}

/* Chamadas numéricas */
sup.chamada-numerica-sobrescrito {
  font-size:      0.75em;
  vertical-align: super;
  line-height:    0;
}

span.chamada-numerica-colchetes,
span.chamada-numerica-parenteses {
  font-size: inherit;
}

/* ═══════════════════════════════════════════════════════════════════════
   SUPRESSÃO E INTERPOLAÇÃO EM CITAÇÕES
   ═══════════════════════════════════════════════════════════════════════ */

span.supressao {
  font-style: normal;
}

span.interpolacao {
  font-style: normal;
}

span.nota-grifo {
  font-style:  italic;
  font-size:   0.9em;
}

span.traducao-livre {
  font-style: normal;
}

span.nota-traducao {
  font-style: italic;
  font-size:  0.9em;
}

/* ═══════════════════════════════════════════════════════════════════════
   NOTAS DE RODAPÉ / NOTAS DE FIM
   ═══════════════════════════════════════════════════════════════════════ */

sup.indicador-nota {
  font-size:      0.75em;
  vertical-align: super;
  line-height:    0;
}

sup.indicador-nota a.link-nota {
  color:           var(--cor-link);
  text-decoration: none;
}

sup.indicador-nota a.link-nota:hover {
  text-decoration: underline;
}

aside.notas-rodape {
  margin-top: 2em;
}

hr.separador-notas {
  border:        none;
  border-top:    1px solid #cccccc;
  width:         30%;
  margin:        1em 0;
  margin-left:   0;
}

ol.lista-notas {
  list-style:    none;
  padding-left:  0;
  font-size:     10pt;
  line-height:   var(--espacamento-simples);
}

li.item-nota {
  margin-bottom: 0.5em;
  padding-left:  2em;
  text-indent:   -2em;
  text-align:    justify;
}

span.numero-nota {
  font-size:      0.85em;
  vertical-align: super;
  line-height:    0;
  margin-right:   0.25em;
}

a.retorno-nota {
  color:           var(--cor-link);
  text-decoration: none;
  margin-left:     0.25em;
  font-size:       0.85em;
}

/* ═══════════════════════════════════════════════════════════════════════
   SEÇÃO DE REFERÊNCIAS BIBLIOGRÁFICAS
   NBR 10520:2023 §8 + NBR 6023:2018
   ═══════════════════════════════════════════════════════════════════════ */

section.referencias {
  margin-top: 3em;
}

div.lista-referencias {
  margin-top: 1em;
}

div.referencia {
  text-align:    justify;
  text-indent:   0;
  margin-bottom: 0.5em;
  line-height:   var(--espacamento-simples);
  font-size:     var(--tamanho-corpo);
  /* Entrada de referência: primeira linha à esquerda, demais recuadas *)*/
  /* NBR 6023:2018 não obriga hanging indent, mas é prática comum *)*/
  padding-left:  0;
}

/* Título da obra em negrito — padrão atual NBR 6023:2018 *)*/
div.referencia strong.titulo-obra,
div.referencia strong.nome-periodico,
div.referencia strong.titulo-anais,
div.referencia strong.nome-evento,
div.referencia strong.titulo-legislacao,
div.referencia strong.titulo-obra-hospedeira {
  font-weight: bold;
  font-style:  normal;
}

/* Autores: sobrenome em caixa alta, prenome normal *)*/
span.sobrenome-referencia {
  text-transform: uppercase;
  font-weight:    normal;
}

/* Links de URL nas referências *)*/
a.url-referencia,
a.doi-link {
  color:           var(--cor-link);
  word-break:      break-all;
  text-decoration: none;
}

a.url-referencia:hover,
a.doi-link:hover {
  text-decoration: underline;
  color:           var(--cor-link-hover);
}

a.link-referencia-texto {
  color:           inherit;
  text-decoration: none;
}

a.link-referencia-texto:hover {
  text-decoration: underline;
}

/* ═══════════════════════════════════════════════════════════════════════
   CABEÇALHO E IDENTIFICAÇÃO DO DOCUMENTO
   ═══════════════════════════════════════════════════════════════════════ */

header.documento-cabecalho {
  text-align:    center;
  margin-bottom: 3em;
}

div.identificacao-documento p {
  margin: 0.25em 0;
}

p.instituicao,
p.departamento {
  text-transform: uppercase;
  font-weight:    bold;
}

p.subtitulo-documento {
  font-size: 12pt;
}

p.autor-documento {
  margin-top: 1.5em;
}

p.orientador,
p.coorientador {
  margin-top: 0.5em;
  font-size:  11pt;
}

span.rotulo {
  font-weight: bold;
}

p.local-data {
  margin-top: 2em;
}

/* ═══════════════════════════════════════════════════════════════════════
   RODAPÉ DO DOCUMENTO
   ═══════════════════════════════════════════════════════════════════════ */

footer.documento-rodape {
  margin-top:  3em;
  padding-top: 1em;
  border-top:  1px solid #cccccc;
  font-size:   9pt;
  color:       #666666;
  text-align:  center;
}

/* ═══════════════════════════════════════════════════════════════════════
   INDICADORES DE ERRO/AVISO EDITORIAL
   Auxiliam revisores a identificar dados ausentes ou inconsistentes.
   ═══════════════════════════════════════════════════════════════════════ */

span.referencia-nao-encontrada {
  color:          var(--cor-erro);
  font-weight:    bold;
  border-bottom:  2px dotted var(--cor-erro);
}

span.dado-ausente {
  color:          var(--cor-aviso);
  font-style:     italic;
  border-bottom:  1px dotted var(--cor-aviso);
}

/* ═══════════════════════════════════════════════════════════════════════
   ACESSIBILIDADE — CONTEÚDO SOMENTE PARA LEITORES DE TELA
   ═══════════════════════════════════════════════════════════════════════ */

.sr-only {
  position:  absolute;
  width:     1px;
  height:    1px;
  padding:   0;
  margin:    -1px;
  overflow:  hidden;
  clip:      rect(0, 0, 0, 0);
  white-space: nowrap;
  border:    0;
}

/* ═══════════════════════════════════════════════════════════════════════
   MEDIA QUERY PARA IMPRESSÃO — Configurações de página @print
   ═══════════════════════════════════════════════════════════════════════ */

@media print {
  body {
    font-size:   12pt;
    line-height: 1.5;
    color:       #000000;
    background:  #ffffff;
    padding:     0;
    margin:      0;
  }

  @page {
    margin-top:    3cm;
    margin-bottom: 2cm;
    margin-left:   3cm;
    margin-right:  2cm;
    size:          A4 portrait;
  }

  @page :first {
    margin-top: 3cm;
  }

  /* Evitar quebras de página dentro de referências *)*/
  div.referencia {
    page-break-inside: avoid;
  }

  /* Evitar quebras de página dentro de citações longas *)*/
  blockquote.citacao-direta-longa {
    page-break-inside: avoid;
  }

  /* Cabeçalho e rodapé na impressão *)*/
  header.documento-cabecalho {
    page-break-after: always;
  }

  /* Ocultar elementos de navegação na impressão *)*/
  a.retorno-nota,
  a.link-nota {
    text-decoration: none;
    color: #000000;
  }

  a.url-referencia::after,
  a.doi-link::after {
    content: " [" attr(href) "]";
    font-size: 9pt;
    color: #333333;
  }
}

/* ═══════════════════════════════════════════════════════════════════════
   RESPONSIVIDADE — Adaptação para dispositivos móveis (leitura/revisão)
   ═══════════════════════════════════════════════════════════════════════ */

@media screen and (max-width: 768px) {
  :root {
    --recuo-citacao-longa: 2cm;
    --margem-esquerda:     1cm;
    --margem-direita:      1cm;
    --margem-superior:     1cm;
    --margem-inferior:     1cm;
  }

  body {
    padding: 1cm;
  }

  blockquote.citacao-direta-longa {
    margin-left: var(--recuo-citacao-longa);
  }
}
    </xsl:text>
  </xsl:template>


  <!-- ═══════════════════════════════════════════════════════════════════════
       SEÇÃO 16 — TEMPLATES DE PASSAGEM (IDENTITY TRANSFORM)
       Propaga elementos e atributos não tratados explicitamente.
       ═══════════════════════════════════════════════════════════════════════ -->

  <!--
    Template identidade: replica nós de texto e atributos sem transformação.
    Essencial para preservar conteúdo textual aninhado nos elementos citados.
  -->
  <xsl:template match="text()">
    <xsl:value-of select="."/>
  </xsl:template>

  <!--
    Elementos desconhecidos: processa filhos sem envolvê-los em HTML.
    Garante que o conteúdo não seja silenciosamente descartado.
  -->
  <xsl:template match="*[not(self::documento) and
                          not(self::corpo) and
                          not(self::secao) and
                          not(self::subsecao) and
                          not(self::paragrafo) and
                          not(self::p) and
                          not(self::citacao) and
                          not(self::nota) and
                          not(self::nota-rodape) and
                          not(self::referencia) and
                          not(self::referencias) and
                          not(self::metadados) and
                          not(self::configuracao)]">
    <xsl:apply-templates/>
  </xsl:template>

</xsl:stylesheet>
