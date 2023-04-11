<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="html" />

  <xsl:param name="show-item-title" />

  <!-- Links to official documentation -->
  <xsl:variable name="manuals">
    <link key="ffmpeg" url="https://ffmpeg.org/ffmpeg.html" />
    <link key="ffmpeg-resampler" url="https://ffmpeg.org/ffmpeg-resampler.html" />
    <link key="ffmpeg-scaler" url="https://ffmpeg.org/ffmpeg-scaler.html" />
    <link key="ffmpeg-utils" url="https://ffmpeg.org/ffmpeg-utils.html" />
  </xsl:variable>

  <!-- Block items -->

  <xsl:template match="texinfo">
    <doc><xsl:apply-templates /></doc>
  </xsl:template>

  <xsl:template match="chapter">
    <group>
      <xsl:attribute name="title" select="sectiontitle" />
      <xsl:apply-templates />
    </group>
  </xsl:template>

  <xsl:template match="section">
    <section>
      <xsl:attribute name="data-title" select="sectiontitle" />

      <xsl:if test="$show-item-title">
        <h1 class="title"><xsl:value-of select="sectiontitle" /></h1>
      </xsl:if>

      <xsl:call-template name="direct-link-anchor" />

      <xsl:apply-templates />
    </section>
  </xsl:template>

  <xsl:template match="subsection">
    <section>
      <xsl:if test="sectiontitle/text() = 'Examples'">
        <xsl:attribute name="class">examples</xsl:attribute>
      </xsl:if>

      <xsl:call-template name="direct-link-anchor" />

      <h2><xsl:value-of select="sectiontitle" /></h2>
      <xsl:apply-templates />
    </section>
  </xsl:template>

  <xsl:template match="para">
    <p><xsl:apply-templates /></p>
  </xsl:template>

  <xsl:template match="example/pre">
    <pre class="example"><xsl:apply-templates /></pre>
  </xsl:template>

  <xsl:template match="verbatim">
    <pre class="verbatim"><xsl:apply-templates /></pre>
  </xsl:template>

  <xsl:template match="table[.//tableitem/*]">
    <!--
      A table with non-empty <tableitem> elements is rendered as a description list.

      Adjacent <tableentry> with no <tableitem> are joined in a single <dt>.
    -->
    <dl>
      <xsl:attribute name="class">
        <xsl:value-of select="@commandarg" />
      </xsl:attribute>

      <xsl:for-each-group select="tableentry" group-ending-with="*[./tableitem]">
        <dt>
          <xsl:for-each select="current-group()">
            <xsl:if test="position() gt 1">
              <span class="separator"><xsl:text>,&#32;</xsl:text></span>
            </xsl:if>
            <xsl:apply-templates select="tableterm" />
          </xsl:for-each>
        </dt>
        <dd><xsl:apply-templates select="current-group()/tableitem" /></dd>
      </xsl:for-each-group>
    </dl>
  </xsl:template>

  <xsl:template match="table">
    <ul>
      <xsl:attribute name="class">
        <xsl:value-of select="@commandarg" />
      </xsl:attribute>
      <xsl:for-each select="tableentry">
        <li><xsl:apply-templates select="tableterm" /></li>
      </xsl:for-each>
    </ul>
  </xsl:template>

  <xsl:template match="itemize[@commandarg='bullet']">
    <ul>
      <xsl:for-each select="listitem">
        <li><xsl:apply-templates /></li>
      </xsl:for-each>
    </ul>
  </xsl:template>

  <xsl:template match="sectiontitle">
    <!--
      Ignore this element, since its contents are applied with <xsl:value-of>.
    -->
  </xsl:template>

  <!-- Inline items -->

  <xsl:template match="ref[./xrefinfoname]">
    <a>
      <xsl:attribute name="href">
        <xsl:text>label:</xsl:text>
        <xsl:value-of select="@label" />
      </xsl:attribute>

      <xsl:apply-templates select="xrefinfoname" />
    </a>
  </xsl:template>

  <xsl:template match="ref[@manual]">
    <xsl:variable name="manual" select="@manual" />
    <a>
      <xsl:attribute name="href">
        <xsl:value-of select="$manuals/link[@key=$manual]/@url" />
        <xsl:text>#</xsl:text>
        <xsl:value-of select="@label" />
      </xsl:attribute>
      <xsl:value-of select="xrefprinteddesc" />
    </a>
  </xsl:template>

  <xsl:template match="ref">
    <a>
      <xsl:attribute name="href">
        <xsl:text>label:</xsl:text>
        <xsl:value-of select="@label" />
      </xsl:attribute>

      <xsl:apply-templates />
    </a>
  </xsl:template>

  <xsl:template match="url/urefurl">
    <a target="_blank">
      <xsl:attribute name="href"><xsl:value-of select="." /></xsl:attribute>
      <xsl:value-of select="." />
    </a>
  </xsl:template>

  <xsl:template match="code">
    <code><xsl:apply-templates /></code>
  </xsl:template>

  <xsl:template match="itemformat">
    <span>
      <xsl:attribute name="class">
        <xsl:value-of select="@command" />
      </xsl:attribute>
      <xsl:apply-templates />
    </span>
  </xsl:template>

  <xsl:template match="itemize[@commandarg='bullet']/listitem/prepend">
    <!-- Ignore &bullet; items -->
  </xsl:template>

  <xsl:template match="anchor">
    <!-- Ignore -->
  </xsl:template>

  <!-- Shared templates -->

  <xsl:template name="direct-link-anchor">
    <xsl:variable name="ref-name">
      <xsl:choose>
        <xsl:when test="@ref-name">
          <xsl:value-of select="@ref-name" />
        </xsl:when>

        <xsl:otherwise>
          <xsl:value-of select="translate(normalize-space(sectiontitle), ' #/:,', '')" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <a class="direct-link">
      <xsl:attribute name="name"><xsl:value-of select="$ref-name" /></xsl:attribute>
      <xsl:attribute name="href">
        <xsl:text>#</xsl:text>
        <xsl:value-of select="$ref-name" />
      </xsl:attribute>
      <xsl:text>#</xsl:text>
    </a>
  </xsl:template>

</xsl:stylesheet>
