<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="html" />

  <!-- Links to official documentation -->
  <xsl:variable name="manuals">
    <link key="ffmpeg" url="https://ffmpeg.org/ffmpeg.html" />
    <link key="ffmpeg-resampler" url="https://ffmpeg.org/ffmpeg-resampler.html" />
    <link key="ffmpeg-scaler" url="https://ffmpeg.org/ffmpeg-scaler.html" />
    <link key="ffmpeg-utils" url="https://ffmpeg.org/ffmpeg-utils.html" />
  </xsl:variable>

  <!-- Block items -->

  <xsl:template match="section">
    <section>
      <h1 class="title"><xsl:value-of select="sectiontitle" /></h1>
      <xsl:apply-templates />
    </section>
  </xsl:template>

  <xsl:template match="subsection">
    <section>
      <xsl:if test="sectiontitle/text() = 'Examples'">
        <xsl:attribute name="class">examples</xsl:attribute>
      </xsl:if>
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

  <xsl:template match="table[.//tableitem]">
    <!-- A table with <tableitem> elements is rendered as a description list -->
    <dl>
      <xsl:attribute name="class">
        <xsl:value-of select="@commandarg" />
      </xsl:attribute>

      <xsl:for-each select="tableentry">
        <dt><xsl:apply-templates select="tableterm" /></dt>
        <dd><xsl:apply-templates select="tableitem" /></dd>
      </xsl:for-each>
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

  <xsl:template match="ref[@manual]">
    <xsl:variable name="manual" select="@manual" />
    <a>
      <xsl:attribute name="href">
        <xsl:value-of
          xmlns:libxslt="http://xmlsoft.org/XSLT/namespace"
          select="libxslt:node-set($manuals)/link[@key=$manual]/@url" />
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

</xsl:stylesheet>
