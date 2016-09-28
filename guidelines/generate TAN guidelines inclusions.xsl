<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://docbook.org/ns/docbook" xmlns:docbook="http://docbook.org/ns/docbook"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math"
   xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:saxon="http://icl.com/saxon"
   xmlns:lxslt="http://xml.apache.org/xslt" xmlns:redirect="http://xml.apache.org/xalan/redirect"
   xmlns:exsl="http://exslt.org/common" xmlns:doc="http://nwalsh.com/xsl/documentation/1.0"
   xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:rng="http://relaxng.org/ns/structure/1.0" xmlns:sch="http://purl.oclc.org/dsdl/schematron"
   xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:a="http://relaxng.org/ns/compatibility/annotations/1.0"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
   xpath-default-namespace="http://docbook.org/ns/docbook"
   extension-element-prefixes="saxon redirect lxslt exsl" exclude-result-prefixes="#all"
   version="3.0">
   <xd:doc scope="stylesheet">
      <xd:desc>
         <xd:p><xd:b>Updated </xd:b> Sept 27, 2016</xd:p>
         <xd:p>The input xml file to this stylesheet is immaterial. The stylesheet will transform
            all the TAN schema files into a series of Docbook inclusions for the TAN guidelines,
            documenting the structural rules, the validation rules, the schematron quick
            fixes.</xd:p>
      </xd:desc>
   </xd:doc>
   <xsl:output method="xml" indent="no"/>

   <xsl:include href="../functions/incl/TAN-core-functions.xsl"/>
   <xsl:include href="../functions/incl/TAN-schema-functions.xsl"/>
   <xsl:include href="inclusions/rng-to-text.xsl"/>
   <xsl:include href="inclusions/tan-snippet-to-docbook.xsl"/>
   <xsl:include href="inclusions/tan-keywords-to-docbook.xsl"/>

   <xsl:param name="indent-value" select="3"/>
   <xsl:variable name="indent"
      select="
         string-join(for $i in (1 to $indent-value)
         return
            ' ')"/>
   <xsl:param name="max-examples" select="4"/>
   <xsl:param name="qty-contextual-siblings" select="1"/>
   <xsl:param name="qty-contextual-children" select="3"/>

   <xsl:variable name="ex-collection"
      select="
         collection('../examples/?select=*.xml;recurse=yes'),
         collection('../TAN-key/?select=*.xml;recurse=yes')"/>
   <xsl:variable name="fn-collection" select="collection('../functions/?select=*.xsl;recurse=yes')"/>
   <xsl:variable name="keyword-collection"
      select="collection('../TAN-key/?select=*key.xml;recurse=yes')"/>
   <xsl:variable name="elements-excl-TEI" select="$rng-collection-without-TEI//rng:element[@name]"/>
   <xsl:variable name="attributes-excl-TEI" select="$rng-collection-without-TEI//rng:attribute[@name]"/>
   <xsl:variable name="distinct-element-names" select="distinct-values($elements-excl-TEI/@name)"/>
   <xsl:variable name="distinct-attribute-names" select="distinct-values($attributes-excl-TEI/@name)"/>

   <xsl:variable name="lf" select="'&#xA;'"/>
   <xsl:variable name="lt" select="'&lt;'"/>
   <xsl:variable name="ellipses" select="'.........&#xA;'"/>
   
   <xsl:variable name="sequence-of-sections" as="xs:string+"
      select="('TAN-core', 'TAN-class-1', 'TAN-T', 'TAN-class-2', 'TAN-A-div', 'TAN-A-tok', 'TAN-LM', 'TAN-class-3', 'TAN-key', 'TAN-mor', 'TAN-rdf')"
   />

   <xsl:template match="/*">
      <xsl:result-document href="inclusions/elements-attributes-and-patterns.xml">
         <chapter version="5.0">
         <title>TAN patterns, elements, and attributes defined</title>
         <para>
            <xsl:value-of
               select="'The ' || count($distinct-element-names) || ' elements and ' || count($distinct-attribute-names) || ' attributes defined in TAN, excluding TEI, are the following::'"
            />
         </para>
         <para>
            <xsl:for-each-group select="($attributes-excl-TEI, $elements-excl-TEI)" group-by="name() || ' ' || @name">
               <xsl:sort select="lower-case(@name)"/>
               <xsl:variable name="node-type-and-name" select="tokenize(current-grouping-key(),'\s+')"/>
               <xsl:copy-of
                  select="tan:prep-string-for-docbook(tan:node-string-norm($node-type-and-name[2], $node-type-and-name[1]))"
               />
               <xsl:text> </xsl:text>
            </xsl:for-each-group>  
         </para>
         <xsl:for-each select="$rng-collection-without-TEI">
               <xsl:sort
                  select="index-of($sequence-of-sections, replace(base-uri(.), '.+/(.+)\.rng$', '$1'))"
               />
            <xsl:variable name="this-rng" select="."/>
            <xsl:variable name="this-name"
               select="replace(base-uri($this-rng), '.+/(.+)\.rng$', '$1')"/>
            <section>
               <title>
                  <xsl:value-of
                     select="$this-name || ' elements, attributes, and patterns summarized'"/>
               </title>
               <xsl:for-each-group select="$this-rng//rng:element" group-by="@name">
                  <xsl:sort select="lower-case(current-grouping-key())"/>
                  <xsl:call-template name="rng-node-to-docbook-section">
                     <xsl:with-param name="rng-element-or-attribute-group" select="current-group()"
                     />
                  </xsl:call-template>
               </xsl:for-each-group>
               <xsl:for-each-group select="$this-rng//rng:attribute" group-by="@name">
                  <xsl:sort select="lower-case(current-grouping-key())"/>
                  <xsl:call-template name="rng-node-to-docbook-section">
                     <xsl:with-param name="rng-element-or-attribute-group" select="current-group()"
                     />
                  </xsl:call-template>
               </xsl:for-each-group>
               <xsl:if test="not(exists($this-rng//(rng:element, rng:attribute)))">
                  <para>
                     <xsl:value-of
                        select="'No attributes or elements are defined for ' || $this-name || '.'"/>
                  </para>
               </xsl:if>
            </section>
         </xsl:for-each>
         <section>
            <title>TAN patterns</title>
            <xsl:for-each-group
               select="$rng-collection-without-TEI//rng:define"
               group-by="@name">
               <xsl:sort select="lower-case(@name)"/>
               <xsl:call-template name="rng-node-to-docbook-section">
                  <xsl:with-param name="rng-element-or-attribute-group" select="current-group()"/>
               </xsl:call-template>
            </xsl:for-each-group>
         </section>
      </chapter>
      </xsl:result-document>
      <xsl:result-document href="inclusions/keywords.xml">
         <chapter version="5.0">
            <xsl:variable name="intro-text" as="xs:string">In this section are collected all
               official TAN keywords, i.e., values of @which predefined by TAN for certain elements.
               Remember, these keywords are not @xml:id values. They may contain punctuation,
               spaces, and so forth. For more on the use of these keywords, see @which, specific
               elements, or various examples. </xsl:variable>
            <title>Official TAN keywords</title>
            <para>
               <xsl:copy-of select="tan:prep-string-for-docbook(normalize-space($intro-text))"/></para>
            <xsl:apply-templates select="$keyword-collection" mode="keyword-to-docbook"/>
         </chapter>
      </xsl:result-document>
   </xsl:template>
   <xsl:template name="rng-node-to-docbook-section">
      <!-- This is the main mechanism for populating sections that document an element or attribute -->
      <xsl:param name="rng-element-or-attribute-group" as="element()*"/>
      <xsl:variable name="this-group" select="$rng-element-or-attribute-group"/>
      <xsl:variable name="this-node-type" select="name($this-group[1])"/>
      <xsl:variable name="this-node-name" select="$this-group[1]/@name"/>
      <xsl:variable name="containing-definitions" select="$this-group/parent::rng:define"/>
      <xsl:variable name="possible-parents-of-this-node"
         select="
            $this-group/(ancestor::rng:element, rng:define)[last()],
            $rng-collection-without-TEI//rng:ref[@name = ($this-node-name, $containing-definitions/@name)]/(ancestor::rng:element, ancestor::rng:define)[last()]"/>
      <xsl:variable name="possible-parents-norm">
         <xsl:for-each select="$possible-parents-of-this-node">
            <xsl:variable name="this-name" select="@name"/>
            <xsl:choose>
               <xsl:when test="count(rng:*) gt 1 or not(rng:element or rng:attribute)">
                  <xsl:sequence select="."/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:sequence
                     select="$rng-collection-without-TEI//rng:ref[@name = ($this-name)]/(ancestor::rng:element, ancestor::rng:define)[last()]"
                  />
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each>
      </xsl:variable>
      <section xml:id="{$this-node-type || '-' || replace($this-node-name,':','')}">
         <title>
            <code>
               <xsl:copy-of select="tan:node-string-norm($this-node-name, $this-node-type)"/>
            </code>
         </title>
         <!-- part 1, documentation -->
         <xsl:apply-templates select="$this-group/a:documentation" mode="rng-to-docbook"/>
         <!-- part 2, formal definiton -->
         <synopsis>
            <emphasis>Formal Definition&#xa;</emphasis>
            <xsl:for-each select="$this-group">
               <xsl:if test="position() gt 1"> OR &#xa;</xsl:if>
               <xsl:if test="count($this-group) gt 1">
                  <xsl:value-of select="'[' || replace(base-uri(.), '.+/(.+)\.rng$', '$1') || '] '"/>
               </xsl:if>
               <xsl:apply-templates select="rng:*" mode="formaldef">
               <xsl:with-param name="current-indent" select="$indent" tunnel="yes"/>
            </xsl:apply-templates>
            <xsl:if test="not(rng:*)">
               <xsl:text>text</xsl:text>
            </xsl:if>
         </xsl:for-each>
         </synopsis>
         <!-- part 3, parents -->
         <xsl:if test="exists($possible-parents-of-this-node)">
            <para>
               <xsl:text>Used by: </xsl:text>
               <xsl:for-each select="$possible-parents-of-this-node">
                  <xsl:if test="position() gt 1">
                     <xsl:text>, </xsl:text>
                  </xsl:if>
                  <xsl:copy-of
                     select="tan:prep-string-for-docbook(tan:node-string-norm(@name, name(.)))"/>
               </xsl:for-each>
            </para>
         </xsl:if>
         <!-- part 4 and 5, errors and warnings and examples -->
         <xsl:choose>
            <xsl:when test="$this-node-type = 'element'">
               <xsl:apply-templates mode="errors-to-docbook"
                  select="$errors//tan:group[tokenize(@affects-element, '\s+') = $this-node-name]/tan:*"/>
               <xsl:copy-of select="tan:examples($this-node-name, false())"/>
            </xsl:when>
            <xsl:when test="$this-node-type = 'attribute'">
               <xsl:apply-templates mode="errors-to-docbook"
                  select="$errors//tan:group[tokenize(@affects-attribute, '\s+') = $this-node-name]/tan:*"/>
               <xsl:copy-of select="tan:examples($this-node-name, true())"/>
            </xsl:when>
         </xsl:choose>
      </section>
   </xsl:template>

   <xsl:mode name="rng-to-docbook" on-no-match="shallow-copy"/>
   <xsl:template match="a:documentation[parent::rng:element or parent::rng:attribute]"
      mode="rng-to-docbook">
      <xsl:variable name="parent-type" select="lower-case(name(..))"/>
      <para>
         <xsl:if test="not(preceding-sibling::a:documentation)">
            <xsl:value-of select="'The ' || $parent-type || ' '"/>
            <code>
               <xsl:value-of select="../@name"/>
            </code>
            <xsl:text> </xsl:text>
         </xsl:if>
         <xsl:copy-of select="tan:prep-string-for-docbook(.)"/>
      </para>
   </xsl:template>
   <xsl:template match="a:documentation[parent::rng:define]" mode="rng-to-docbook">
      <xsl:variable name="this-name" select="replace(base-uri(.), '.+/(.+)\.rng$', '$1')"/>
      <para>
         <xsl:value-of select="$this-name || ': '"/>
         <xsl:copy-of select="tan:prep-string-for-docbook(.)"/>
      </para>
   </xsl:template>

   <xsl:function name="tan:prep-string-for-docbook" as="item()*">
      <xsl:param name="text" as="xs:string"/>
      <xsl:variable name="pass-1" as="item()*">
         <!-- let the ~ represent a pattern, similar to the @ prefix to signal an attribute -->
         <xsl:analyze-string select="$text" regex="{$lt || '[-:\w+]+>|[~@][-:\w+]+'}">
            <xsl:matching-substring>
               <xsl:variable name="linkend-prefix" as="xs:string?">
                  <xsl:choose>
                     <xsl:when test="matches(., '^@')">
                        <xsl:text>attribute</xsl:text>
                     </xsl:when>
                     <xsl:when test="matches(., '^~')">
                        <xsl:text>define</xsl:text>
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:text>element</xsl:text>
                     </xsl:otherwise>
                  </xsl:choose>
               </xsl:variable>
               <code>
                  <link linkend="{$linkend-prefix|| '-'|| replace(., '[~&lt;@>:]', '')}">
                     <xsl:value-of select="."/>
                  </link>
               </code>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
               <xsl:analyze-string select="." regex="main\.xml#[-_\w]+|iris\.xml|https?://\S+">
                  <xsl:matching-substring>
                     <xsl:choose>
                        <xsl:when test="starts-with(., 'main')">
                           <xref linkend="{replace(.,'main\.xml#','')}"/>
                        </xsl:when>
                        <xsl:otherwise>
                           <link xlink:href="{.}">
                              <xsl:value-of select="."/>
                           </link>
                        </xsl:otherwise>
                     </xsl:choose>
                  </xsl:matching-substring>
                  <xsl:non-matching-substring>
                     <xsl:value-of select="."/>
                  </xsl:non-matching-substring>
               </xsl:analyze-string>
            </xsl:non-matching-substring>
         </xsl:analyze-string>
      </xsl:variable>
      <xsl:copy-of select="$pass-1"/>
   </xsl:function>

   <xsl:function name="tan:node-string-norm" as="xs:string">
      <xsl:param name="node-name" as="xs:string"/>
      <xsl:param name="node-type" as="xs:string"/>
      <xsl:choose>
         <xsl:when test="$node-type = 'attribute'">
            <xsl:value-of select="'@' || $node-name"/>
         </xsl:when>
         <xsl:when test="$node-type = 'element'">
            <xsl:value-of select="$lt || $node-name || '>'"/>
         </xsl:when>
         <xsl:when test="$node-type = ('pattern', 'define')">
            <xsl:value-of select="'~' || $node-name"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:value-of select="$node-name"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

   <!-- part 4, errors -->
   <xsl:mode name="errors-to-docbook" on-no-match="shallow-skip"/>
   <xsl:template match="tan:error | tan:fatal" mode="errors-to-docbook">
      <caution>
         <para>
            <xsl:copy-of select="tan:prep-string-for-docbook(tan:rule)"/>
         </para>
      </caution>
   </xsl:template>
   <xsl:template match="tan:warning" mode="errors-to-docbook">
      <important>
         <para>
            <xsl:copy-of select="tan:prep-string-for-docbook(tan:rule)"/>
            <xsl:if test="exists(tan:message)">
               <xsl:copy-of select="tan:prep-string-for-docbook(tan:rule)"/>
            </xsl:if>
         </para>
      </important>
   </xsl:template>
   <xsl:template match="tan:info" mode="errors-to-docbook">
      <info>
         <para>
            <xsl:copy-of select="tan:prep-string-for-docbook(tan:rule)"/>
         </para>
      </info>
   </xsl:template>

</xsl:stylesheet>
