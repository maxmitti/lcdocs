<?xml version="1.0" encoding="ISO-8859-1"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="2.0" xmlns:clonk="https://clonkspot.org" xpath-default-namespace="https://clonkspot.org" exclude-result-prefixes="xs">

	<xsl:output method="html" encoding="ISO-8859-1" doctype-public="-//W3C//DTD HTML 4.01//EN"
				doctype-system="http://www.w3.org/TR/html4/strict.dtd"/>

	<xsl:param name="is-web-documentation"/>
	<xsl:param name="fileext" select="'.xml'"/>
	<xsl:param name="output-folder"/>
	<xsl:param name="input-folder"/>

	<xsl:template name="main">
		<xsl:for-each select="collection(concat($input-folder, '?select=*.xml;recurse=yes'))">
			<xsl:variable name="procinst" select="processing-instruction('xml-stylesheet')"/>
			<xsl:variable name="relpath" select="substring-after(substring-before($procinst, 'clonk.xsl'),'href=&quot;')"/>
			<xsl:variable name="target-filepath" select="concat($output-folder, '/' , substring-before(substring-after(base-uri(.), $input-folder), '.xml'), $fileext)"/>
			<xsl:variable name="relpath-to-language-root">
				<xsl:for-each select="1 to (count(tokenize($target-filepath, '/')) - 3)">../</xsl:for-each>
			</xsl:variable>
			<!-- Logging current handled file for debugging warnings-->
			<!-- 2023-01-01 Funni: Need to use base-uri as document-uri for compatibility with Saxon HE 11.4 https://saxonica.plan.io/issues/5339 -->
			<xsl:message><xsl:text>Transforming </xsl:text><xsl:value-of select="$target-filepath"></xsl:value-of> </xsl:message>

			<!--<xsl:result-document href="out/sdk/{tokenize(document-uri(.), '/')[last()]}"> packing everything in one folder-->
			<!--	online/de/sdk [output-folder] + (/...../sdk/index.xml [document-uri] - everything before sdk/ [input-folder] - ".xml") + .html	-->
			<xsl:result-document href="{concat($output-folder, '/' , substring-before(substring-after(base-uri(.), $input-folder), '.xml'), $fileext)}">
				<xsl:apply-templates select=".">
					<xsl:with-param name="relpath" select="$relpath" tunnel="yes"/>
					<xsl:with-param name="relpath-to-language-root" select="$relpath-to-language-root" tunnel="yes"/>
					<xsl:with-param name="navbar" select="doc(concat('developer/templates/navbar-snippet-', /clonkDoc/@xml:lang ,'.html'))" tunnel="yes"/>
				</xsl:apply-templates>
			</xsl:result-document>
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="head">
		<xsl:param name="relpath" tunnel="yes"/>
		<xsl:param name="relpath-to-language-root" tunnel="yes"/>
		<head>
			<link rel="stylesheet" type="text/css">
				<xsl:attribute name="href">
					<xsl:value-of select="$relpath-to-language-root"/><xsl:text>../resources/css/doku.css</xsl:text>
				</xsl:attribute>
			</link>
			<title>
				<xsl:value-of select="descendant::title"/>
				<xsl:apply-templates select="../deprecated"/>
			</title>
			<!-- LF Linebreak for better readability -->
			<xsl:text>&#xa;</xsl:text>
			<xsl:if test="descendant::*[@activateBitmask='true']">
				<script type="text/javascript">
					<xsl:attribute name="src">
						<xsl:value-of select="$relpath-to-language-root"/><xsl:text>../resources/js/bitmask.js</xsl:text>
					</xsl:attribute>
				</script>
				<xsl:text>&#xa;</xsl:text>
			</xsl:if>
			<xsl:if test="$is-web-documentation">
				<xsl:processing-instruction name="php">
					<xsl:text>&#xa;      $g_page_language = '</xsl:text>
					<xsl:choose>
						<xsl:when test='lang("en")'>english</xsl:when>
						<xsl:otherwise>german</xsl:otherwise>
					</xsl:choose>
					<xsl:text>';</xsl:text>
					<xsl:text>&#xa;      require_once('</xsl:text><xsl:value-of select="$relpath"/><xsl:text>../webnotes/core/api.php');</xsl:text>
					<xsl:text>&#xa;      pwn_head();</xsl:text>
					<xsl:text>&#xa;      ?</xsl:text>
				</xsl:processing-instruction>
				<xsl:text>&#xa;</xsl:text>
				<script type="text/javascript">
					function switchLanguage() {
						var loc = window.location.href;
						if (loc.match(/\/en\//)) loc = loc.replace(/\/en\//, "/de/");
						else loc = loc.replace(/\/de\//, "/en/");
						window.location.href = loc;
					}
				</script>
				<xsl:text>&#xa;</xsl:text>
			</xsl:if>
		</head>
	</xsl:template>
	<!-- The title content is used for the page title-->
	<xsl:template match="title"/>
	<xsl:template match="func/deprecated">
		<xsl:text> (</xsl:text>
		<xsl:choose>
			<xsl:when test='lang("de") and ./version != "unknown"'>
				<xsl:text>veraltet seit </xsl:text>
				<xsl:value-of select="normalize-space(./version)"/>
			</xsl:when>
			<xsl:when test='./version != "unknown"'>
				<xsl:text>deprecated since </xsl:text>
				<xsl:value-of select="normalize-space(./version)"/>
			</xsl:when>
			<xsl:when test='lang("de")'>veraltet</xsl:when>
			<xsl:otherwise>deprecated</xsl:otherwise>
		</xsl:choose>
		<xsl:text>)</xsl:text>
	</xsl:template>

	<xsl:template match="/clonkDoc">
		<xsl:param name="navbar" tunnel="yes"/>
		<html>
			<xsl:call-template name="head"/>
			<body>
				<xsl:apply-templates select="$navbar//ul[@class = 'nav']" xpath-default-namespace="" mode="fix-links"/>
				<xsl:apply-templates select="func"/>
				<xsl:apply-templates select="doc"/>
				<xsl:apply-templates select="constGroup"/>
				<xsl:apply-templates select="author"/>

				<xsl:if test="$is-web-documentation">
					<xsl:processing-instruction name="php">
						<xsl:text>pwn_body(basename (dirname(__FILE__)) . basename(__FILE__,".html"), $_SERVER['SCRIPT_NAME']); ?</xsl:text>
					</xsl:processing-instruction>
				</xsl:if>
				<xsl:apply-templates select="$navbar//ul[@class = 'nav']" xpath-default-namespace="" mode="fix-links"/>

			</body>
		</html>
	</xsl:template>

	<!-- Import Navbar -->
	<!-- https://stackoverflow.com/questions/74944291/copy-of-with-search-and-replace-relative-paths -->
	<xsl:template mode="fix-links" match="@* | node()" xpath-default-namespace="">
		<xsl:copy>
			<xsl:apply-templates select="@* | node()" mode="#current"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template mode="fix-links" match="ul/li/a/@href" xpath-default-namespace="">
		<xsl:param name="relpath-to-language-root" tunnel="yes"/>
		<xsl:choose>
			<xsl:when test="not(starts-with(., 'javascript:'))">
				<xsl:attribute name="{name()}" select="concat($relpath-to-language-root, .)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:attribute name="{name()}" select="."/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template mode="fix-links" match="ul/li/a/img/@src" xpath-default-namespace="">
		<xsl:param name="relpath-to-language-root" tunnel="yes"/>
		<xsl:attribute name="{name()}" select="concat($relpath-to-language-root, .)"/>
	</xsl:template>


	<xsl:template match="doc">
		<xsl:apply-templates select="title"/>
		<xsl:apply-templates select="h|part|text|code|dl|img"/>
		<xsl:call-template name="history"/>
	</xsl:template>

	<xsl:template match="func">
		<xsl:param name="relpath-to-language-root" tunnel="yes"/>
		<h1>
			<xsl:value-of select="title"/>
			<xsl:apply-templates select="deprecated"/>
		</h1>
		<div class="text">
			<xsl:apply-templates select="category"/>
			<br/>
			<xsl:apply-templates select="versions"/>
		</div>
		<h2>
			<xsl:choose>
				<xsl:when test='lang("de")'>Beschreibung</xsl:when>
				<xsl:otherwise>Description</xsl:otherwise>
			</xsl:choose>
		</h2>
		<div class="text">
			<xsl:if test="@isAsync = true()">
				<xsl:variable as="xs:string" name="path-to-async-page" select="'fillme.html'"/> <!-- TODO -->
				<div class="alertBoxPreDescription">
					<xsl:choose>
						<xsl:when test='lang("en")'>
							<b>Asynchronous function</b><br/>
							This function may trigger asynchronous behavior or return asynchronous results and must therefore be used with caution. See <a><xsl:attribute
								name="href" select="concat($relpath-to-language-root, 'sdk/', $path-to-async-page)"/>"Asynchronous functions" description page</a> for more information.
						</xsl:when>
						<xsl:otherwise>
							<b>Asynchrone Funktion</b><br/>
							Diese Funktion kann asynchrones Verhalten auslösen oder asynchrone Ergebnisse liefern und muss daher mit Bedacht verwendet werden. Siehe <a><xsl:attribute
								name="href" select="concat($relpath-to-language-root, 'sdk/', $path-to-async-page)"/>Beschreibungsseite "Asynchrone Funktionen"</a> für weitere Informationen.
						</xsl:otherwise>
					</xsl:choose>
				</div>
			</xsl:if>
			<xsl:apply-templates select="desc"/>
		</div>
		<xsl:apply-templates select="syntax"/>
		<xsl:for-each select="syntax">
			<xsl:for-each select="params">
				<h2><xsl:text>Parameter</xsl:text>
					<xsl:if test="count(param)!=1 and lang('en')">s</xsl:if>
				</h2>
				<dl>
					<xsl:for-each select="param">
						<dt><xsl:value-of select="name"/>:
						</dt>
						<dd>
							<div class="text">
								<xsl:if test="@isOptional = true()">
									<xsl:text>[optional] </xsl:text>
								</xsl:if>
								<xsl:apply-templates select="desc"/>
							</div>
						</dd>
					</xsl:for-each>
				</dl>
			</xsl:for-each>
		</xsl:for-each>
		<xsl:for-each select="remark">
			<xsl:if test="generate-id(.)=generate-id(../remark[1])">
				<h2>
					<xsl:choose>
						<xsl:when test='lang("en")'>Remark
							<xsl:if test="count(../remark)!=1">s</xsl:if>
						</xsl:when>
						<xsl:otherwise>Anmerkung
							<xsl:if test="count(../remark)!=1">en</xsl:if>
						</xsl:otherwise>
					</xsl:choose>
				</h2>
			</xsl:if>
			<div class="text">
				<xsl:apply-templates/>
			</div>
		</xsl:for-each>
		<xsl:call-template name="examples"/>
		<xsl:call-template name="history"/>
		<xsl:apply-templates select="related"/>
	</xsl:template>

	<xsl:template match="constGroup">
		<h1>
			<xsl:value-of select="title"/>
		</h1>
		<div class="text">
			<xsl:apply-templates select="category"/>
		</div>
		<xsl:if test="description">
			<h2>
				<xsl:choose>
					<xsl:when test='lang("de")'>Beschreibung</xsl:when>
					<xsl:otherwise>Description</xsl:otherwise>
				</xsl:choose>
			</h2>
			<div class="text">
				<xsl:apply-templates select="description"/>
			</div>
		</xsl:if>
		<h2>
			<xsl:choose>
				<xsl:when test="lang('de')">Konstanten</xsl:when>
				<xsl:otherwise>Constants</xsl:otherwise>
			</xsl:choose>
		</h2>
		<xsl:choose>
			<xsl:when test="@activateBitmask='true'">
				<div>
					<xsl:attribute name="class">bitmaskTable</xsl:attribute>
					<xsl:call-template name="constTable"/>
					<xsl:call-template name="bitmaskBitfield"/>
				</div>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="constTable"/>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:call-template name="examples"/>
		<xsl:call-template name="history"/>
	</xsl:template>

	<xsl:template name="constTable">
		<table class="text">
			<thead>
				<tr>
					<th>Name</th>
					<th>
						<xsl:choose>
							<xsl:when test="lang('de')">Kategorie</xsl:when>
							<xsl:otherwise>Category</xsl:otherwise>
						</xsl:choose>
					</th>
					<th>
						<xsl:choose>
							<xsl:when test="lang('de')">Beschreibung</xsl:when>
							<xsl:otherwise>Description</xsl:otherwise>
						</xsl:choose>
					</th>
					<th>
						<xsl:choose>
							<xsl:when test="lang('de')">Eingeführt in</xsl:when>
							<xsl:otherwise>Introduced in</xsl:otherwise>
						</xsl:choose>
					</th>
					<th>
						<xsl:choose>
							<xsl:when test="lang('de')">Wert</xsl:when>
							<xsl:otherwise>Value</xsl:otherwise>
						</xsl:choose>
					</th>
				</tr>
			</thead>
			<tbody>
				<xsl:for-each select="const">
					<tr>
						<xsl:if test="exists(@bitPos)">
							<xsl:attribute name="data-custom-bit-pos" select="@bitPos"/>
						</xsl:if>
						<xsl:if test="position() mod 2=0">
							<xsl:attribute name="class">dark</xsl:attribute>
						</xsl:if>
						<xsl:if test="descendant::deprecated">
							<xsl:attribute name="class">strikeout</xsl:attribute>
						</xsl:if>
						<td>
							<xsl:attribute name="id" select="./name"/>
							<xsl:if test="descendant::deprecated">
								<span>
									<xsl:attribute name="class">deprecatedComment</xsl:attribute>
									<xsl:attribute name="style">display:none; position:absolute;</xsl:attribute>
									<xsl:choose>
										<xsl:when test="lang('de')">
											<xsl:text >Als veraltet markiert ab Version </xsl:text>
											<xsl:value-of select="normalize-space(descendant::deprecated/version)"/>
											<xsl:text> durch </xsl:text>
											<xsl:value-of select="normalize-space(descendant::deprecated/author)"/>
											<xsl:text> am </xsl:text>
											<xsl:apply-templates select="descendant::deprecated/date"/>
											<xsl:text>. Weitere Informationen in Änderungsliste.</xsl:text>
										</xsl:when>
										<xsl:otherwise>
											<xsl:text >Marked as deprecated in Version </xsl:text>
											<xsl:value-of select="normalize-space(descendant::deprecated/version)"/>
											<xsl:text> by </xsl:text>
											<xsl:value-of select="normalize-space(descendant::deprecated/author)"/>
											<xsl:text> (</xsl:text>
											<xsl:apply-templates select="descendant::deprecated/date"/>
											<xsl:text>). For more information see history section.</xsl:text>
										</xsl:otherwise>
									</xsl:choose>
								</span>
							</xsl:if>
							<xsl:apply-templates select="./name"/>
						</td>
						<td><xsl:value-of select="normalize-space(./category)"/></td>
						<td><xsl:apply-templates select="./description"/></td>
						<td><xsl:value-of select="normalize-space(./version)"/></td>
						<td><xsl:value-of select="normalize-space(./value)"/></td>
					</tr>
				</xsl:for-each>
			</tbody>
		</table>
	</xsl:template>

	<xsl:template match="syntax">
		<h2>Syntax</h2>
		<div class="text fnsyntax">
			<span class="type">
				<xsl:value-of select="rtype"/>
				<xsl:if test="rtype/@isReference = true()">
					<xsl:text>&#38;</xsl:text>
				</xsl:if>
			</span>
			<xsl:text>&#160;</xsl:text>
			<xsl:value-of select="../title"/>
			(<xsl:apply-templates select="params"/>);
		</div>
	</xsl:template>

	<xsl:template match="params">
		<xsl:for-each select="param">
			<xsl:apply-templates select="."/>
			<xsl:if test="position()!=last()"><xsl:text>, </xsl:text></xsl:if>
		</xsl:for-each>
	</xsl:template>

	<xsl:template match="param">
		<span class="type">
			<xsl:value-of select="type"/>
			<xsl:if test="@isReference = true()">
				<xsl:text>&#38;</xsl:text>
			</xsl:if>
		</span>
			<xsl:text>&#160;</xsl:text>
		<xsl:value-of select="name"/>
	</xsl:template>

	<xsl:template match="category">
		<b>
			<xsl:choose>
				<xsl:when test='lang("en")'>Category: </xsl:when>
				<xsl:otherwise>Kategorie: </xsl:otherwise>
			</xsl:choose>
		</b>
		<xsl:value-of select="."/>
		<xsl:apply-templates select="../subcat"/>
	</xsl:template>

	<xsl:template match="subcat">
		<xsl:text> / </xsl:text>
		<xsl:value-of select="."/>
	</xsl:template>

	<xsl:template match="versions">
		<b>
			<xsl:choose>
				<xsl:when test='lang("en")'>Since engine version: </xsl:when>
				<xsl:otherwise>Ab Engineversion: </xsl:otherwise>
			</xsl:choose>
		</b>
		<xsl:value-of select="normalize-space(version)"/>
		<xsl:apply-templates select="extversion[1]"/>
	</xsl:template>

	<xsl:template match="extversion">
		<xsl:choose>
			<xsl:when test='lang("de")'>
				<xsl:text> (erweitert in </xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text> (extended in </xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:value-of select="normalize-space(.)"/>
		<xsl:for-each select="following::extversion">
			<xsl:choose>
				<xsl:when test="position() != last()">
					<xsl:text>, </xsl:text><xsl:value-of select="normalize-space(.)" />
				</xsl:when>
				<xsl:when test='position() = last() and lang("de")'>
					<xsl:text> und </xsl:text><xsl:value-of select="normalize-space(.)" />
				</xsl:when>
				<xsl:when test='position() = last()'>
					<xsl:text> and </xsl:text><xsl:value-of select="normalize-space(.)" />
				</xsl:when>
			</xsl:choose>
		</xsl:for-each>
		<xsl:text>)</xsl:text>
	</xsl:template>

	<xsl:template name="examples">
		<xsl:if test="exists(examples)">
			<h2>
				<xsl:choose>
					<xsl:when test='lang("de")'><xsl:text>Beispiel</xsl:text>
						<xsl:if test="count(examples/example)!=1">e</xsl:if>
					</xsl:when>
					<xsl:otherwise><xsl:text>Example</xsl:text>
						<xsl:if test="count(examples/example)!=1">s</xsl:if>
					</xsl:otherwise>
				</xsl:choose>
			</h2>
			<xsl:apply-templates select="examples/example"/>
		</xsl:if>
	</xsl:template>

	<xsl:template match="example">
		<div class="example">
			<xsl:apply-templates/>
		</div>
	</xsl:template>

	<xsl:template name="history">
			<xsl:if test="exists(//deprecated) or exists(//history)">
				<h2>
					<xsl:choose>
						<xsl:when test="lang('de')">Änderungshistorie</xsl:when>
						<xsl:otherwise>Changelog</xsl:otherwise>
					</xsl:choose>
				</h2>
				<table class="text">
					<thead>
						<tr>
							<th>
								<xsl:choose>
									<xsl:when test="lang('de')">Datum</xsl:when>
									<xsl:otherwise>Date</xsl:otherwise>
								</xsl:choose>
							</th>
							<th>
								<xsl:choose>
									<xsl:when test="lang('de')">Autor</xsl:when>
									<xsl:otherwise>Author</xsl:otherwise>
								</xsl:choose>
							</th>
							<th>Version</th>
							<!-- If we have multiple entities in a file like <const>s in a <constGroup> we should name it in a separate column-->
							<xsl:if test="exists(ancestor-or-self::constGroup)">
								<th>
									<xsl:choose>
										<xsl:when test="lang('de')">Betrifft</xsl:when>
										<xsl:otherwise>Affecting</xsl:otherwise>
									</xsl:choose>
								</th>
							</xsl:if>
							<th>
								<xsl:choose>
									<xsl:when test="lang('de')">Änderungen</xsl:when>
									<xsl:otherwise>Description</xsl:otherwise>
								</xsl:choose>
							</th>
						</tr>
					</thead>
					<tbody>
						<xsl:if test="//history">
							<xsl:for-each select="//history/change">
								<tr>
									<xsl:if test="position() mod 2=0">
										<xsl:attribute name="class">dark</xsl:attribute>
									</xsl:if>
									<td><xsl:apply-templates select="./date"/></td>
									<td><xsl:value-of select="normalize-space(./author)"/></td>
									<td><xsl:value-of select="normalize-space(./version)"/></td>
									<!-- If we have an iterable like <const>s in a <constGroup> we should name it in a separate column-->
									<xsl:if test="exists(./ancestor::constGroup)">
										<td>
											<xsl:value-of select="./affecting"/>
										</td>
									</xsl:if>
									<td><xsl:apply-templates select="./description"/></td>
								</tr>
							</xsl:for-each>
						</xsl:if>
						<xsl:for-each select="//deprecated">
							<tr>
								<td><xsl:apply-templates select="./date"/></td>
								<td><xsl:value-of select="normalize-space(./author)"/></td>
								<td>
									<xsl:choose>
										<xsl:when test='./version != "unknown"'>
											<xsl:value-of select="normalize-space(./version)"/>
										</xsl:when>
										<xsl:when test='lang("de")'>unbekannt</xsl:when>
										<xsl:otherwise>unknown</xsl:otherwise>
									</xsl:choose>
								</td>
								<!-- If we have a deprecated iterable like <const>s in a <constGroup> we should name it in a separate column-->
								<xsl:if test="exists(./ancestor::const)">
									<td>
										<xsl:value-of select="./ancestor::const/name"/>
									</td>
								</xsl:if>
								<td>
									<b>
										<xsl:choose>
											<xsl:when test='lang("de")'><xsl:text>Veraltet: </xsl:text></xsl:when>
											<xsl:otherwise><xsl:text>Deprecated: </xsl:text></xsl:otherwise>
										</xsl:choose>
									</b>
									<xsl:apply-templates select="./description"/></td>
							</tr>
						</xsl:for-each>
					</tbody>
				</table>
			</xsl:if>
	</xsl:template>

	<xsl:template match="text">
		<div class="text">
			<xsl:apply-templates/>
		</div>
	</xsl:template>

	<xsl:template match="part">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="@id">
		<xsl:attribute name="id">
			<xsl:value-of select="."/>
		</xsl:attribute>
	</xsl:template>
	<xsl:template match="doc/h">
		<h1>
			<xsl:apply-templates select="@id|node()"/>
		</h1>
	</xsl:template>
	<xsl:template match="doc/part/h">
		<h2>
			<xsl:apply-templates select="@id|node()"/>
		</h2>
	</xsl:template>
	<xsl:template match="doc/part/part/h">
		<h3>
			<xsl:apply-templates select="@id|node()"/>
		</h3>
	</xsl:template>
	<xsl:template match="doc/part/part/part/h">
		<h4>
			<xsl:apply-templates select="@id|node()"/>
		</h4>
	</xsl:template>

	<!-- copy img, a, em and br literally -->
	<xsl:template match="img|a|em|strong|br|code/i|code/b|tt">
		<xsl:element name="{local-name()}">
			<!-- including every attribute -->
			<xsl:for-each select="@*">
				<xsl:attribute name="{local-name()}"><xsl:value-of select="."/></xsl:attribute>
			</xsl:for-each>
			<xsl:apply-templates/>
		</xsl:element>
	</xsl:template>

	<xsl:template match="dl">
		<dl>
			<xsl:apply-templates select="dt|dd"/>
		</dl>
	</xsl:template>
	<xsl:template match="dt">
		<dt>
			<xsl:apply-templates select="@id|node()"/>
		</dt>
	</xsl:template>
	<xsl:template match="dd">
		<dd>
			<xsl:apply-templates/>
		</dd>
	</xsl:template>

	<xsl:template match="related">
		<div class="text">
			<b>
				<xsl:choose>
					<xsl:when test='lang("en")'><xsl:text>See also: </xsl:text></xsl:when>
					<xsl:otherwise><xsl:text>Siehe auch: </xsl:text></xsl:otherwise>
				</xsl:choose>
			</b>
			<xsl:for-each select="*">
				<xsl:sort/>
				<xsl:apply-templates select="."/>
				<xsl:if test="position()!=last()"><xsl:text>, </xsl:text></xsl:if>
			</xsl:for-each>
		</div>
	</xsl:template>

	<xsl:template match="funcLink">
		<xsl:param name="relpath-to-language-root" tunnel="yes"/>
		<xsl:choose>
			<xsl:when test="doc-available(concat('sdk/script/fn/', normalize-space(.), '.xml'))">
				<a>
					<xsl:attribute name="href">
						<xsl:value-of select="$relpath-to-language-root"/><xsl:text>sdk/script/fn/</xsl:text><xsl:value-of select="normalize-space(.)"/><xsl:value-of
							select="$fileext"/>
					</xsl:attribute>
					<xsl:value-of select="normalize-space(.)"/>
				</a>
			</xsl:when>
			<xsl:otherwise>
				<!-- TODO set terminate=yes when running in production-->
				<xsl:message terminate="no">Can't find the function "<xsl:value-of select="normalize-space(.)"/>"</xsl:message>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="emLink" name="link">
		<xsl:param name="relpath-to-language-root" tunnel="yes"/>
		<!-- so this template can be called for the navigation -->
		<xsl:param name="href" select="normalize-space(@href)"/>
		<xsl:param name="text" select="normalize-space(.)"/>
		<xsl:param name="icon" select="@icon" required="no"/>
		<a>
			<xsl:attribute name="href">
				<xsl:value-of select="$relpath-to-language-root"/><xsl:text>sdk/</xsl:text>
				<xsl:choose>
					<!-- replace the .html extension with .xml (or whatever) depending on $fileext param (.chm, .html etc.) -->
					<xsl:when test="substring-before($href,'.html')">
						<xsl:value-of
								select="concat(substring-before($href,'.html'), $fileext, substring-after($href,'.html'))"/>
						<xsl:if test="not(doc-available(concat('sdk/', substring-before($href,'.html'), '.xml')))">
							<!-- TODO set terminate=yes when running in production-->
							<xsl:message terminate="no">Can't find the resource <xsl:value-of select="concat('sdk/', substring-before($href,'.html'), '.xml')"/></xsl:message>
						</xsl:if>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$href"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
			<xsl:if test="$icon">
				<img alt='Icon'>
					<xsl:attribute name="src"><xsl:value-of select="$icon"/></xsl:attribute>
				</img>
			</xsl:if>
			<xsl:value-of select="$text"/>
		</a>
	</xsl:template>

	<xsl:template match="constLink">
		<xsl:param name="relpath-to-language-root" tunnel="yes"/>
		<xsl:param name="constGroup" select="@constGroup"/>
		<xsl:choose>
			<xsl:when test="doc-available(concat('sdk/script/constants/', $constGroup, '.xml'))">
				<a>
					<xsl:attribute name="href">
						<xsl:value-of select="$relpath-to-language-root"/><xsl:text>sdk/script/constants/</xsl:text><xsl:value-of select="$constGroup"/><xsl:value-of
							select="$fileext"/>
						<xsl:if test=". != ''"><xsl:text>#</xsl:text><xsl:value-of select="normalize-space(.)"/></xsl:if>
					</xsl:attribute>
					<xsl:choose>
						<xsl:when test=". != ''">
							<xsl:value-of select="normalize-space(.)"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="$constGroup"/>
							<xsl:choose>
								<xsl:when test='lang("de")'><xsl:text>-Konstantengruppe</xsl:text></xsl:when>
								<xsl:otherwise><xsl:text>-constant group</xsl:text></xsl:otherwise>
						</xsl:choose>
						</xsl:otherwise>
					</xsl:choose>
				</a>
			</xsl:when>
			<xsl:otherwise>
				<xsl:message terminate="yes">Can't find the constant "<xsl:value-of select="normalize-space(.)"/>"</xsl:message>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="callbackLink">
		<xsl:param name="relpath-to-language-root" tunnel="yes"/>
		<xsl:choose>
			<xsl:when test="doc-available(concat('sdk/script/fn/callbacks/', normalize-space(.), '.xml'))">
				<a>
					<xsl:attribute name="href">
						<xsl:value-of select="$relpath-to-language-root"/><xsl:text>sdk/script/fn/callbacks/</xsl:text><xsl:value-of select="normalize-space(.)"/><xsl:value-of
							select="$fileext"/>
					</xsl:attribute>
					<xsl:value-of select="normalize-space(.)"/>
				</a>
			</xsl:when>
			<xsl:otherwise>
				<xsl:message terminate="yes">Can't find the callback function "<xsl:value-of select="normalize-space(.)"/>"</xsl:message>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="author">
		<div class="author"><xsl:value-of select="normalize-space(.)"/><xsl:text>, </xsl:text>
			<xsl:apply-templates select="following-sibling::date[1]"/>
		</div>
	</xsl:template>

	<xsl:template match="date">
		<xsl:choose>
			<xsl:when test="count(tokenize(., '-'))=2">
				<!--
				2023-01-01 Funni
				format-date() blocks from using Saxon higher than 9.1 as from there only English is supported in Saxon HE.
				https://saxonica.com/documentation10/index.html#!configuration/configuration-file
				https://stackoverflow.com/questions/5571345/xslt-2-0-month-name-in-french-or-german
				https://www.saxonica.com/html/documentation10/functions/fn/format-dateTime.html
				https://stackoverflow.com/questions/64466680/how-to-set-language-data-with-saxon-he-10-2
				Therefore this blocks from using XSLT 3.0 as it was introduced with Saxon 9.8: https://www.saxonica.com/documentation11/index.html#!using-xsl/xslt30
				-->
					<xsl:value-of select="format-date(xs:date(concat(., '-01')), '[MNn] [Y]', /clonkDoc/@xml:lang, (), ())"/>
			</xsl:when>
			<xsl:when test="count(tokenize(., '-'))=3">
				<xsl:value-of select="format-date(xs:date(.), '[D1o] [MNn] [Y]', /clonkDoc/@xml:lang, (), ())"/>
			</xsl:when>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="ul">
		<ul>
			<xsl:apply-templates/>
		</ul>
	</xsl:template>

	<xsl:template match="li">
		<li>
			<xsl:apply-templates/>
		</li>
	</xsl:template>

	<xsl:template match="table">
		<xsl:choose>
			<xsl:when test="@activateBitmask='true'">
				<div>
					<xsl:attribute name="class">bitmaskTable</xsl:attribute>
					<xsl:call-template name="table"/>
					<xsl:call-template name="bitmaskBitfield"/>
				</div>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="table"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="table/caption">
		<caption>
			<xsl:apply-templates select="@id|node()"/>
		</caption>
	</xsl:template>

	<xsl:template name="table">
		<table>
			<xsl:apply-templates select="caption"/>
			<xsl:apply-templates select="rowh"/>
			<tbody>
				<xsl:for-each select="row">
					<tr>
						<xsl:apply-templates select="@id"/>
						<xsl:if test="position() mod 2=0">
							<xsl:attribute name="class">dark</xsl:attribute>
						</xsl:if>
						<xsl:if test="descendant::deprecated">
							<xsl:attribute name="class">strikeout</xsl:attribute>
						</xsl:if>
						<xsl:for-each select="col">
							<td>
								<xsl:if test="following-sibling::deprecated and position()=1">
									<span>
										<xsl:attribute name="class">deprecatedComment</xsl:attribute>
										<xsl:attribute name="style">display:none; position:absolute;</xsl:attribute>
										<xsl:choose>
											<xsl:when test="lang('de')">
												<xsl:text >Als Veraltet markiert ab Version </xsl:text>
												<xsl:value-of select="normalize-space(following-sibling::deprecated/version)"/>
												<xsl:text> durch </xsl:text>
												<xsl:value-of select="normalize-space(following-sibling::deprecated/author)"/>
												<xsl:text> am </xsl:text>
												<xsl:apply-templates select="following-sibling::deprecated/date"/>
												<xsl:text>. Weitere Informationen in Änderungsliste.</xsl:text>
											</xsl:when>
											<xsl:otherwise>
												<xsl:text >Marked as deprecated in Version </xsl:text>
												<xsl:value-of select="normalize-space(following-sibling::deprecated/version)"/>
												<xsl:text> by </xsl:text>
												<xsl:value-of select="normalize-space(following-sibling::deprecated/author)"/>
												<xsl:text> (</xsl:text>
												<xsl:apply-templates select="following-sibling::deprecated/date"/>
												<xsl:text>). For more information see history section.</xsl:text>
											</xsl:otherwise>
										</xsl:choose>
									</span>
								</xsl:if>

								<xsl:apply-templates select="@colspan|node()"/>
							</td>
						</xsl:for-each>
					</tr>
				</xsl:for-each>
			</tbody>
		</table>
	</xsl:template>

	<xsl:template name="bitmaskBitfield">
		<xsl:if test="@activateBitmask='true'">
			<xsl:call-template name="bitmaskValidation"/>
			<label>
				<xsl:choose>
					<xsl:when test="name(.) = 'constGroup'">
						<xsl:choose>
							<xsl:when test='lang("de")'><xsl:text>Wert der Bitmaske</xsl:text></xsl:when>
							<xsl:otherwise><xsl:text>Bitmask value</xsl:text></xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<xsl:otherwise><xsl:value-of select="@bitmaskName"/></xsl:otherwise>
				</xsl:choose>
				<xsl:text>: </xsl:text>
				<input type="number" value="0" disabled="true"/>
				<xsl:call-template name="link">
					<xsl:with-param name="href" select="'script/operatoren.html#Bitweise'"/>
					<xsl:with-param name="text">
						<xsl:choose>
							<xsl:when test='lang("de")'><xsl:text>Weitere Informationen zu Bitmasken</xsl:text></xsl:when>
							<xsl:otherwise><xsl:text>More information about Bitmasks</xsl:text></xsl:otherwise>
						</xsl:choose>
					</xsl:with-param>
					<xsl:with-param name="icon" select="'/images/question-mark-round-line.svg'"/>
				</xsl:call-template>
			</label>
		</xsl:if>
	</xsl:template>
	
	<xsl:template name="bitmaskValidation">
		<xsl:if test="name(.) = 'constGroup'">
			<xsl:if test="exists(const/@bitPos)">
				<xsl:for-each select="const">
					<xsl:if test="@bitPos &lt; 0 or @bitPos > 32">
						<xsl:message terminate="yes"><xsl:text>Invalid bit position set in constant "</xsl:text><xsl:value-of select="./name"/><xsl:text>". The maximum allowed bit position for bitmasks is 32 as clonk uses a 32-bit integer.</xsl:text></xsl:message>
					</xsl:if>
				</xsl:for-each>
				<xsl:if test="not(count(const/@bitPos) = count(const))">
					<xsl:message terminate="yes"><xsl:text>Invalid constellation in bitmask: Counted </xsl:text><xsl:value-of select="count(const)"/><xsl:text> constants but </xsl:text><xsl:value-of select="count(const/@bitPos)"/><xsl:text> "bitPos"-attributes. Every const-node needs a "bitPos" attribute if any const-node has one.</xsl:text></xsl:message>
				</xsl:if>
			</xsl:if>
			<xsl:if test="count(const) > 32">
				<xsl:message terminate="yes">Invalid constellation in bitmask: Counted <xsl:value-of select="count(const)"/> const-elements. The maximum allowed const-elements for bitmasks is 32 as clonk uses a 32-bit integer.</xsl:message>
			</xsl:if>
		</xsl:if>
		<xsl:if test="name(.) = 'table' and count(row) > 32">
			<xsl:message terminate="yes">Invalid constellation in bitmask: Counted <xsl:value-of select="count(row)"/> rows. The maximum allowed rows for bitmasks is 32 as clonk uses a 32-bit integer.</xsl:message>
		</xsl:if>
	</xsl:template>

	<xsl:template match="rowh">
		<thead>
			<tr>
				<xsl:apply-templates select="@id"/>
				<xsl:for-each select="col">
					<th>
						<xsl:apply-templates select="@colspan|node()"/>
					</th>
				</xsl:for-each>
			</tr>
		</thead>
	</xsl:template>
	<xsl:template match="@colspan">
		<xsl:attribute name="colspan">
			<xsl:value-of select="."/>
		</xsl:attribute>
	</xsl:template>

	<!-- some code blocks are made into paragraphs -->
	<xsl:template match="example/code|part/code|doc/code|dd/code">
		<pre class="code">
			<xsl:apply-templates/>
		</pre>
	</xsl:template>
	<xsl:template match="code">
		<xsl:copy>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>

	<!-- Highlight Comments and Strings -->
	<xsl:template name="color1" match="code/text()">
		<xsl:param name="s" select="."/>
		<!-- /**/, //\n -->
		<xsl:param name="tl" select="'/*|//|'"/>
		<xsl:param name="tr" select="'*/|&#10;|'"/>
		<xsl:param name="wl" select="substring-before($tl, '|')"/>
		<xsl:param name="wr" select="substring-before($tr, '|')"/>
		<!-- the text before the start marker -->
		<xsl:variable name="l" select="substring-before($s, $wl)"/>
		<!-- the text between the start marker and the end marker -->
		<xsl:variable name="m" select="substring-before(substring-after($s, $wl), $wr)"/>
		<!-- the text after $l and $m -->
		<xsl:variable name="r" select="substring($s, string-length(concat($l, $wl, $m, $wr)) + 1)"/>
		<xsl:choose>
			<!-- something to highlight -->
			<xsl:when test="$m">
				<!-- look for the next pair -->
				<xsl:call-template name="color1">
					<xsl:with-param name="s" select="$l"/>
					<!-- the text after the current keyword and before the next | -->
					<xsl:with-param name="wl" select="substring-before(substring-after($tl, concat($wl, '|')), '|')"/>
					<xsl:with-param name="wr" select="substring-before(substring-after($tr, concat($wr, '|')), '|')"/>
				</xsl:call-template>
				<i>
					<!-- comments in italic -->
					<xsl:value-of select="concat($wl, $m, $wr)"/>
				</i>
				<!-- look for the next occurrence of the current pair -->
				<xsl:call-template name="color1">
					<xsl:with-param name="s" select="$r"/>
				</xsl:call-template>
			</xsl:when>
			<!-- pairs left? -->
			<xsl:when test="string-length($wr)!=0">
				<xsl:call-template name="color1">
					<xsl:with-param name="s" select="$s"/>
					<xsl:with-param name="wl" select="substring-before(substring-after($tl, concat($wl, '|')), '|')"/>
					<xsl:with-param name="wr" select="substring-before(substring-after($tr, concat($wr, '|')), '|')"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<!-- proceed with the keywords -->
				<xsl:call-template name="color-strings">
					<xsl:with-param name="s" select="$s"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- Hightlight stuff like "foo \" bar" correctly. -->
	<xsl:template name="color-strings">
		<xsl:param name="s" select="."/>
		<!-- the text before the start marker -->
		<xsl:variable name="l" select="substring-before($s, '&quot;')"/>
		<!-- call a template to get the content of the C4Script string -->
		<xsl:variable name="m0">
			<xsl:call-template name="parse-string-escapes">
				<xsl:with-param name="s" select="substring-after($s, '&quot;')"/>
			</xsl:call-template>
		</xsl:variable>
		<!-- then call string() on the resulting tree fragment to get it as an xpath string -->
		<xsl:variable name="m" select="string($m0)"/>
		<!-- the text after $l and $m -->
		<xsl:variable name="r" select="substring($s, string-length(concat($l, $m)) + 3)"/>
		<xsl:choose>
			<!-- something to highlight -->
			<xsl:when test="$m">
				<!-- look for the next pair -->
				<xsl:call-template name="color2">
					<xsl:with-param name="s" select="$l"/>
				</xsl:call-template>
				<i>
					<!-- highlight strings in green -->
					<xsl:attribute name="class">string</xsl:attribute>
					<xsl:value-of select="concat('&quot;', $m, '&quot;')"/>
				</i>
				<!-- look for the next string -->
				<xsl:call-template name="color-strings">
					<xsl:with-param name="s" select="$r"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<!-- proceed with the keywords -->
				<xsl:call-template name="color2">
					<xsl:with-param name="s" select="$s"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="parse-string-escapes">
		<xsl:param name="s" select="."/>
		<xsl:choose>
			<!-- end of string -->
			<xsl:when test="substring($s, 1, 1)='&quot;'">
			</xsl:when>
			<!-- \" -->
			<xsl:when test="substring($s, 1, 2)='\&quot;'">
				<xsl:value-of select="'\&quot;'"/>
				<xsl:call-template name="parse-string-escapes">
					<xsl:with-param name="s" select="substring($s, 3)"/>
				</xsl:call-template>
			</xsl:when>
			<!-- anything else -->
			<xsl:when test="$s">
				<xsl:value-of select="substring($s, 1, 1)"/>
				<xsl:call-template name="parse-string-escapes">
					<xsl:with-param name="s" select="substring($s, 2)"/>
				</xsl:call-template>
			</xsl:when>
		</xsl:choose>
	</xsl:template>

	<!-- Highlight keywords -->
	<xsl:template name="color2">
		<xsl:param name="s" select="."/>
		<!-- the list of keywords -->
		<xsl:param name="t"
				   select="'#include|#strict|#appendto|public|private|protected|global|static|var|local|const|int|id|object|string|bool|array|map|return|goto|if|else|break|continue|while|for|func|true|false|nil|'"/>
		<xsl:param name="w" select="substring-before($t, '|')"/>
		<!-- text before the keyword -->
		<xsl:variable name="l" select="substring-before($s, $w)"/>
		<!-- the charecter directly before the keyword -->
		<xsl:variable name="cb" select="substring($l, string-length($l))"/>
		<!-- text after the keyword -->
		<xsl:variable name="r" select="substring-after($s, $w)"/>
		<!-- the character directly after the keyword -->
		<xsl:variable name="ca" select="substring($r, 1, 1)"/>
		<xsl:choose>
			<xsl:when test="string-length($w)=0">
				<xsl:value-of select="$s"/>
			</xsl:when>
			<!-- only highlight when the text was found and is not surrounded by other text -->
			<xsl:when
					test="($l or $r) and (not(contains('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ', $cb)) or $cb='') and (not(contains('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ', $ca)) or $ca='')">
				<!-- look for the next keyword in the preceding text -->
				<xsl:call-template name="color2">
					<xsl:with-param name="s" select="$l"/>
					<xsl:with-param name="w" select="substring-before(substring-after($t, concat($w, '|')), '|')"/>
				</xsl:call-template>
				<!-- make the keyword bold -->
				<b>
					<xsl:value-of select="$w"/>
				</b>
				<!-- proceed with the remaining text -->
				<xsl:call-template name="color2">
					<xsl:with-param name="s" select="$r"/>
					<xsl:with-param name="w" select="$w"/>
				</xsl:call-template>
			</xsl:when>
			<!-- not found: look for the next keyword -->
			<xsl:otherwise>
				<xsl:call-template name="color2">
					<xsl:with-param name="s" select="$s"/>
					<xsl:with-param name="w" select="substring-before(substring-after($t, concat($w, '|')), '|')"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

</xsl:stylesheet>

