<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math"
   xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns="http://docbook.org/ns/docbook"
   xmlns:saxon="http://icl.com/saxon" xmlns:lxslt="http://xml.apache.org/xslt"
   xmlns:redirect="http://xml.apache.org/xalan/redirect" xmlns:exsl="http://exslt.org/common"
   xmlns:doc="http://nwalsh.com/xsl/documentation/1.0" xmlns:xlink="http://www.w3.org/1999/xlink"
   xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:rng="http://relaxng.org/ns/structure/1.0"
   xmlns:sch="http://purl.oclc.org/dsdl/schematron"
   xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:a="http://relaxng.org/ns/compatibility/annotations/1.0"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
   extension-element-prefixes="saxon redirect lxslt exsl"
   exclude-result-prefixes="xs math xd saxon lxslt redirect exsl doc" version="3.0">
   <xd:doc scope="stylesheet">
      <xd:desc>
         <xd:p><xd:b>Updated </xd:b> Nov 5, 2015</xd:p>
         <xd:p>Stylesheet applied to master-list.xml, to transform all the TAN schema files into a
            series of Docbook inclusions for the TAN guidelines, documenting the structural rules,
            the validation rules, the schematron quick fixes.</xd:p>
      </xd:desc>
   </xd:doc>
   <xsl:output method="xml" indent="no"/>

   <xsl:include href="../../functions/TAN-parameters.xsl"/>

   <xsl:param name="indent-value" select="3"/>
   <xsl:variable name="indent"
      select="
         string-join(for $i in (1 to $indent-value)
         return
            ' ')"/>
   <xsl:param name="max-examples" select="4"/>
   <xsl:param name="qty-contextual-selves" select="3"/>
   <xsl:param name="qty-contextual-siblings" select="1"/>
   <xsl:param name="qty-contextual-children" select="3"/>
   <xsl:param name="schematron-role"
      select="('warn', 'warning', 'fatal', 'error', 'info', 'information')"/>
   <xsl:param name="docbook-alert"
      select="('important', 'important', 'warning', 'warning', 'note', 'note')"/>

   <xsl:variable name="sequence" select="//tan:section/@which"/>
   <xsl:variable name="string-delimiter"
      select="concat('\(', $apos, '?|', $apos, '?,\s+', $apos, '?|', $apos, '?\)|^', $apos, '|', $apos, '$')"/>

   <xsl:variable name="ex-collection"
      select="
         collection('../../examples/?select=*.xml;recurse=yes'),
         collection('../../TAN-R-tok/?select=*.xml;recurse=yes')"/>
   <xsl:variable name="rng-collection"
      select="collection('../../schemas/?select=*.rng;recurse=yes')"/>
   <xsl:variable name="rng-collection-without-TEI"
      select="$rng-collection[not(matches(base-uri(.), 'TAN-TEI'))]"/>
   <xsl:variable name="sch-collection"
      select="collection('../../schemas/?select=*.sch;recurse=yes')"/>
   <xsl:variable name="fn-collection"
      select="collection('../../functions/?select=*.xsl;recurse=yes')"/>
   <xsl:variable name="element-names-excl-TEI"
      select="$rng-collection[not(matches(base-uri(.), 'TAN-TEI'))]//rng:element/@name"/>
   <xsl:variable name="attribute-names-excl-TEI"
      select="$rng-collection[not(matches(base-uri(.), 'TAN-TEI'))]//rng:attribute/@name"/>

   <xsl:variable name="apos" select='"&#x27;"'/>
   <xsl:variable name="lf" select="'&#xA;'"/>
   <xsl:variable name="lt" select="'&lt;'"/>
   <xsl:variable name="ellipses" select="'.........&#xA;'"/>

   <xsl:template match="/tan:*">
      <!-- [X] may be inserted below to restrict to testing a single file; remove it to get everything -->
      <xsl:for-each select="$rng-collection-without-TEI">
         <xsl:variable name="this-rng-pos" select="position()"/>
         <xsl:variable name="this" select="."/>
         <xsl:variable name="this-name" select="replace(base-uri($this), '.+/(.+)\.rng$', '$1')"/>
         <xsl:variable name="these-element-names" as="xs:string*">
            <xsl:for-each select="$this//rng:element/@name">
               <xsl:sort/>
               <xsl:copy-of select="."/>
            </xsl:for-each>
         </xsl:variable>
         <xsl:variable name="these-attribute-names" as="xs:string*">
            <xsl:for-each select="$this//rng:attribute/@name">
               <xsl:sort/>
               <xsl:copy-of select="."/>
            </xsl:for-each>
         </xsl:variable>
         <xsl:variable name="these-element-summaries" as="element()*">
            <xsl:apply-templates select="$this//rng:element">
               <xsl:sort select="lower-case(@name)"/>
            </xsl:apply-templates>
         </xsl:variable>
         <xsl:variable name="these-attribute-summaries" as="element()*">
            <xsl:apply-templates select="$this//rng:attribute">
               <xsl:sort select="lower-case(@name)"/>
            </xsl:apply-templates>
         </xsl:variable>
         <xsl:result-document href="{concat($this-name,'.xml')}">
            <section>
               <xsl:attribute name="version" select="'5.0'"/>
               <title>
                  <xsl:value-of select="$this-name"/> elements and attributes summarized</title>
               <xsl:sequence select="$these-element-summaries"/>
               <xsl:sequence select="$these-attribute-summaries"/>
               <xsl:if test="not(exists($these-element-names) or exists($these-attribute-names))">
                  <para>No attributes or elements are defined for <xsl:value-of select="$this-name"
                     />.</para>
               </xsl:if>
            </section>
         </xsl:result-document>
      </xsl:for-each>
      <xsl:result-document href="index.xml">
         <appendix version="'5.0'">
            <title>Index of Elements and Attributes</title>
            <para>The <xsl:value-of select="count($element-names-excl-TEI)"/> elements and
                  <xsl:value-of select="count($attribute-names-excl-TEI)"/> attributes in TAN are:</para>
            <para>
               <xsl:for-each select="($element-names-excl-TEI,$attribute-names-excl-TEI)">
                  <xsl:sort select="lower-case(.)"/>
                  <xsl:variable name="text"
                     select="
                        if (name(..) = 'element') then
                           concat('&lt;', ., '>')
                        else
                           concat('@', .)"
                  />
                  <xsl:call-template name="code-and-link-element-and-attribute-string-for-docbook">
                     <xsl:with-param name="input-string" select="$text"/>
                  </xsl:call-template>
                  <xsl:text> </xsl:text>
               </xsl:for-each>
            </para>
         </appendix>
      </xsl:result-document>
   </xsl:template>

   <xsl:template match="rng:element | rng:attribute" name="rng-element">
      <xsl:variable name="this-name" select="@name"/>
      <xsl:variable name="is-attribute"
         select="
            if (name() = 'element') then
               false()
            else
               true()"/>
      <xsl:variable name="this-parents"
         select="
            tan:get-parent-elements(./(ancestor::rng:define,
            ancestor::rng:element)[last()])"/>
      <section xml:id="{concat(name(.),'-',replace($this-name,':',''))}">
         <title>
            <code>
               <xsl:value-of
                  select="
                     if ($is-attribute = true()) then
                        concat('@', $this-name)
                     else
                        concat($lt, $this-name, '>')"
               />
            </code>
         </title>
         <xsl:apply-templates select="a:documentation"/>
         <xsl:copy-of select="tan:keyword-documentation($this-name)"/>
         <xsl:variable name="formaldef" as="item()*">
            <xsl:apply-templates select="rng:*" mode="formaldef">
               <xsl:with-param name="current-indent" select="$indent"/>
            </xsl:apply-templates>
            <xsl:if test="not(rng:*)">
               <xsl:text>text</xsl:text>
            </xsl:if>
         </xsl:variable>
         <synopsis>
            <emphasis>
               <xsl:text>Definition:</xsl:text>
            </emphasis>
            <xsl:text>&#xA;</xsl:text>
            <xsl:copy-of select="$formaldef"/>
         </synopsis>
         <para>
            <xsl:text>Used by: </xsl:text>
            <xsl:choose>
               <xsl:when test="exists($this-parents)">
                  <xsl:for-each select="$this-parents">
                     <xsl:sort select="@name"/>
                     <xsl:copy-of select="tan:prep-string-for-docbook(concat($lt, @name, '> '))"/>
                     <!--<code>
                        <xref linkend="{concat('element-',@name)}"/>
                     </code>-->
                  </xsl:for-each>
               </xsl:when>
               <xsl:otherwise>none</xsl:otherwise>
            </xsl:choose>
         </para>
         <xsl:call-template name="schematron-rules">
            <xsl:with-param name="element-or-attribute-name" select="$this-name"/>
            <xsl:with-param name="is-attribute" select="$is-attribute"/>
         </xsl:call-template>
         <xsl:sequence select="tan:examples($this-name, $is-attribute)"/>
      </section>
   </xsl:template>

   <!-- Template for the main human-readable description, also part of tool tips in the XML editor -->
   <xsl:template match="a:documentation">
      <para>
         <xsl:if test="position() = 1">
            <xsl:text>The </xsl:text>
            <xsl:value-of select="lower-case(name(..))"/>
            <xsl:text> </xsl:text>
            <code>
               <xsl:value-of select="../@name"/>
            </code>
            <xsl:text> </xsl:text>
         </xsl:if>
         <xsl:copy-of select="tan:prep-string-for-docbook(.)"/>
      </para>
   </xsl:template>

   <!-- Keyword documentation, for @which values -->
   <xsl:function name="tan:keyword-documentation" as="element()?">
      <xsl:param name="element-name" as="xs:string"/>
      <xsl:variable name="keyword-group"
         select="$keywords//tan:group[tokenize(@affects-element, '\s+') = $element-name]"/>
      <xsl:variable name="guidelines-content-for-keyword" as="xs:string*">
         <xsl:for-each select="$keyword-group//tan:item">
            <xsl:variable name="this-desc"
               select="
                  tan:desc,
                  for $i in tan:desc/@see
                  return
                     doc(resolve-uri($i, base-uri($i)))/*/tan:head/tan:desc"/>
            <xsl:variable name="this-iris"
               select="
                  tan:IRI,
                  for $i in tan:IRI/@see
                  return
                     doc(resolve-uri($i, base-uri($i)))/*/@id"/>
            <xsl:value-of
               select="concat(tan:keyword, ': ', string-join($this-desc, ' '), ' IRI: ', string-join($this-iris, ' '))"
            />
         </xsl:for-each>
      </xsl:variable>
      <xsl:variable name="raw" as="item()*">
         <!--<xsl:if test="exists($keyword-group)">
            <para>
               <xsl:text>The optional attribute @which takes the following keywords: </xsl:text>
               <!-\-<xsl:copy-of
                  select="tan:string-sequence-to-docbook-itemizedlist($guidelines-content-for-keyword)"
               />-\->
               <xsl:apply-templates select="$keyword-group" mode="keyword-prep"/>
            </para>
         </xsl:if>-->
         <xsl:apply-templates select="$keyword-group" mode="keyword-prep"/>
      </xsl:variable>
      <xsl:copy-of select="$raw/*"/>
      <!--<xsl:apply-templates select="$raw" mode="prep-items-for-docbook"/>-->
   </xsl:function>
   <xsl:template match="tan:group" mode="keyword-prep">
      <listitem>
         <para>
            <emphasis>
               <xsl:apply-templates select="tan:desc[1]" mode="keyword-prep"/>
            </emphasis>
            <xsl:apply-templates select="tan:desc[position() gt 1]" mode="keyword-prep"/>
            <itemizedlist>
               <xsl:apply-templates select="tan:group | tan:item" mode="keyword-prep"/>
            </itemizedlist>
         </para>
      </listitem>
   </xsl:template>
   <xsl:template match="tan:item" mode="keyword-prep">
      <xsl:variable name="this-iris"
         select="
            tan:IRI,
            for $i in tan:IRI/@see
            return
               doc(resolve-uri($i, base-uri($i)))/*/@id"/>
      <listitem>
         <para>
            <emphasis role="bold">
               <xsl:value-of select="tan:keyword"/>
            </emphasis>
         </para>
         <xsl:for-each select="distinct-values(.//@see)">
            <para>
               <link xlink:href="{concat('../',.)}">Master file</link>
            </para>
         </xsl:for-each>
         <para>
            <xsl:text>IRI: </xsl:text>
            <code>
               <xsl:value-of select="$this-iris"/>
            </code>
         </para>
         <para>
            <xsl:apply-templates select="tan:desc" mode="keyword-prep"/>
         </para>
      </listitem>
   </xsl:template>
   <xsl:template match="tan:desc" mode="keyword-prep" as="item()*">
      <xsl:variable name="this-desc"
         select="
            if (@see) then
               doc(resolve-uri(@see, base-uri(..)))/*/tan:head/tan:desc
            else
               text()"/>
      <xsl:copy-of select="tan:prep-string-for-docbook($this-desc)"/>
   </xsl:template>

   <!-- Templates for the formal (terse) definition -->
   <!-- @/element suffixes -->
   <xsl:template match="rng:optional" mode="formaldef">
      <xsl:param name="current-indent"/>
      <xsl:apply-templates mode="formaldef">
         <xsl:with-param name="current-indent" select="$current-indent"/>
      </xsl:apply-templates>
      <xsl:text>?</xsl:text>
      <xsl:call-template name="comma-check">
         <xsl:with-param name="current-indent" select="$current-indent"/>
      </xsl:call-template>
   </xsl:template>
   <xsl:template match="rng:zeroOrMore" mode="formaldef">
      <xsl:param name="current-indent"/>
      <xsl:apply-templates mode="formaldef">
         <xsl:with-param name="current-indent" select="$current-indent"/>
      </xsl:apply-templates>
      <xsl:text>*</xsl:text>
      <xsl:call-template name="comma-check">
         <xsl:with-param name="current-indent" select="$current-indent"/>
      </xsl:call-template>
   </xsl:template>
   <xsl:template match="rng:oneOrMore" mode="formaldef">
      <xsl:param name="current-indent"/>
      <xsl:apply-templates mode="formaldef">
         <xsl:with-param name="current-indent" select="$current-indent"/>
      </xsl:apply-templates>
      <xsl:text>+</xsl:text>
      <xsl:call-template name="comma-check">
         <xsl:with-param name="current-indent" select="$current-indent"/>
      </xsl:call-template>
   </xsl:template>
   <!-- options/branches/joins -->
   <xsl:template match="rng:group | rng:choice | rng:interleave" mode="formaldef">
      <xsl:param name="current-indent"/>
      <xsl:variable name="new-indent"
         select="
            if (parent::rng:attribute or parent::rng:element)
            then
               $current-indent
            else
               concat($current-indent, $indent)"
      />
      <xsl:variable name="this-prefix"
         select="
            if (parent::rng:attribute or parent::rng:element)
            then
               ()
            else
               '('"
      />
      <xsl:variable name="this-suffix"
         select="
            if (parent::rng:attribute or parent::rng:element)
            then
               ()
            else
               ')'"
      />
      <xsl:value-of select="concat($new-indent, $this-prefix)"/>
      <xsl:apply-templates mode="formaldef" select="rng:*[1]"/>
      <xsl:apply-templates mode="formaldef" select="rng:*[position() gt 1]">
         <xsl:with-param name="current-indent" select="$new-indent"/>
      </xsl:apply-templates>
      <xsl:value-of select="$this-suffix"/>
      <xsl:call-template name="comma-check">
         <xsl:with-param name="current-indent" select="$new-indent"/>
      </xsl:call-template>
   </xsl:template>
   <!--<xsl:template match="rng:choice | rng:interleave" mode="formaldef">
      <xsl:param name="current-indent"/>
      <!-\-<xsl:value-of select="concat($current-indent, $indent, '(')"/>-\->
      <xsl:value-of select="concat($current-indent,'(')"/>
      <!-\-<xsl:text>(</xsl:text>-\->
      <xsl:apply-templates mode="formaldef" select="rng:*[1]"/>
      <xsl:apply-templates mode="formaldef" select="rng:*[position() gt 1]">
         <!-\-<xsl:with-param name="current-indent" select="concat($current-indent, $indent)"/>-\->
         <xsl:with-param name="current-indent" select="$current-indent"/>
      </xsl:apply-templates>
      <xsl:text>)</xsl:text>
      <xsl:call-template name="comma-check">
         <xsl:with-param name="current-indent" select="$current-indent"/>
      </xsl:call-template>
   </xsl:template>-->
   <xsl:template match="rng:ref" mode="formaldef">
      <xsl:param name="current-indent"/>
      <xsl:variable name="this" select="."/>
      <xsl:variable name="name" select="@name"/>
      <xsl:variable name="defs"
         select="$rng-collection-without-TEI//rng:define[@name = $name][not(rng:empty)]"/>
      <xsl:if test="count($defs) gt 1">
         <xsl:text>&#xA;</xsl:text>
         <xsl:value-of select="$current-indent"/>
      </xsl:if>
      <xsl:for-each select="$defs">
         <xsl:if test="count($defs) gt 1">
            <emphasis>
               <xsl:value-of select="replace(base-uri(.), '.+/(.+)', '$1')"/>
               <xsl:text>:</xsl:text>
            </emphasis>
            <xsl:text>&#xA;</xsl:text>
         </xsl:if>
         <xsl:apply-templates mode="formaldef" select=".">
            <xsl:with-param name="current-indent" select="$current-indent"/>
            <xsl:with-param name="is-group"
               select="
                  if (count(rng:*) gt 1 and ($this/parent::rng:choice or $this/parent::rng:optional)) then
                     true()
                  else
                     false()"
            />
         </xsl:apply-templates>
         <xsl:if test="position() lt last()">
            <xsl:text>&#xA;</xsl:text>
            <emphasis>
               <xsl:text>  ~OR~</xsl:text>
            </emphasis>
            <xsl:text>&#xA;</xsl:text>
         </xsl:if>
      </xsl:for-each>
      <xsl:if test="count($defs) gt 1">
         <xsl:text>&#xA;</xsl:text>
      </xsl:if>
      <xsl:call-template name="comma-check">
         <xsl:with-param name="current-indent" select="$current-indent"/>
      </xsl:call-template>
   </xsl:template>
   <xsl:template match="rng:define[count(rng:*) gt 1]" mode="formaldef">
      <xsl:param name="current-indent"/>
      <xsl:param name="is-group" as="xs:boolean" select="true()"/>
      <xsl:variable name="this-prefix" select="if ($is-group = true()) then '(' else ()"/>
      <xsl:variable name="this-suffix" select="if ($is-group = true()) then ')' else ()"/>
      <xsl:value-of select="concat($current-indent, $this-prefix)"/>
      <!--<xsl:value-of select="$current-indent"/>-->
      <xsl:apply-templates mode="formaldef" select="rng:*[1]"/>
      <xsl:apply-templates mode="formaldef" select="rng:*[position() gt 1]">
         <!--<xsl:with-param name="current-indent" select="concat($current-indent, $indent)"/>-->
         <xsl:with-param name="current-indent" select="$current-indent"/>
      </xsl:apply-templates>
      <xsl:value-of select="$this-suffix"/>
      <!--<xsl:text>)</xsl:text>-->
   </xsl:template>
   <xsl:template match="rng:define[count(rng:*) le 1]" mode="formaldef">
      <xsl:param name="current-indent"/>
      <xsl:apply-templates mode="formaldef">
         <xsl:with-param name="current-indent" select="$current-indent"/>
      </xsl:apply-templates>
   </xsl:template>
   <xsl:template match="rng:element" mode="formaldef">
      <xsl:param name="current-indent"/>
      <xsl:copy-of select="$current-indent"/>
      <xsl:call-template name="code-and-link-element-and-attribute-string-for-docbook">
         <xsl:with-param name="input-string" select="concat('&lt;', @name, '>')"/>
      </xsl:call-template>
      <xsl:call-template name="comma-check">
         <xsl:with-param name="current-indent" select="$current-indent"/>
      </xsl:call-template>
   </xsl:template>
   <xsl:template match="rng:attribute" mode="formaldef">
      <xsl:param name="current-indent"/>
      <!--<xsl:param name="is-first" as="xs:boolean"/>-->
      <xsl:copy-of select="$current-indent"/>
      <xsl:call-template name="code-and-link-element-and-attribute-string-for-docbook">
         <xsl:with-param name="input-string" select="concat('@', @name)"/>
      </xsl:call-template>
      <xsl:call-template name="comma-check">
         <xsl:with-param name="current-indent" select="$current-indent"/>
      </xsl:call-template>
   </xsl:template>
   <xsl:template match="rng:param" mode="formaldef">
      <xsl:param name="current-indent"/>
      <xsl:text>(</xsl:text>
      <xsl:value-of select="@name"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="."/>
      <xsl:text>)</xsl:text>
   </xsl:template>
   <xsl:template match="rng:data" mode="formaldef">
      <xsl:param name="current-indent"/>
      <xsl:value-of
         select="
            if (parent::rng:group | parent::rng:choice | parent::rng:interleave) then
               $current-indent
            else
               ()"
      />
      <xsl:value-of select="@type"/>
      <xsl:text> </xsl:text>
      <xsl:apply-templates mode="formaldef">
         <xsl:with-param name="current-indent" select="$current-indent"/>
      </xsl:apply-templates>
   </xsl:template>
   <xsl:template match="rng:text" mode="formaldef">
      <xsl:text>text</xsl:text>
   </xsl:template>
   <xsl:template match="text() | rng:empty" mode="formaldef"/>
   <xsl:template name="comma-check">
      <xsl:param name="current-indent"/>
      <xsl:choose>
         <xsl:when test="parent::rng:choice and following-sibling::rng:*">
            <xsl:text> |&#xA;</xsl:text>
            <!--<xsl:copy-of select="$current-indent"/>-->
         </xsl:when>
         <xsl:when test="parent::rng:interleave and following-sibling::rng:*">
            <xsl:text> &amp;&#xA;</xsl:text>
            <!--<xsl:copy-of select="$current-indent"/>-->
         </xsl:when>
         <xsl:when test="following-sibling::rng:*">
            <xsl:text>,&#xA;</xsl:text>
            <!--<xsl:copy-of select="$current-indent"/>-->
         </xsl:when>
      </xsl:choose>
   </xsl:template>

   <!-- Template for schematron rules -->
   <xsl:template name="schematron-rules" as="element()*">
      <xsl:param name="element-or-attribute-name" as="xs:string?"/>
      <xsl:param name="is-attribute" as="xs:boolean?"/>
      <xsl:variable name="search-string"
         select="
            if ($is-attribute = true()) then
               concat('@', $element-or-attribute-name, '[^-\w]|@', $element-or-attribute-name, '$')
            else
               concat('tan:', $element-or-attribute-name, '[^-\w]|tan:', $element-or-attribute-name, '$')"/>
      <xsl:variable name="these-rules"
         select="$sch-collection//sch:rule[matches(@context, $search-string) or tokenize(@tan:applies-to, '\s+') = $element-or-attribute-name]"/>
      <xsl:for-each-group
         select="$these-rules/(sch:report, sch:assert)[not(@test = ('false()', 'true()'))][not(tokenize(@tan:does-not-apply-to, '\s+') = $element-or-attribute-name)], $sch-collection//(sch:report, sch:assert)[tokenize(@tan:applies-to, '\s+') = $element-or-attribute-name]"
         group-by="
            if (@role) then
               @role
            else
               'Conditions for validity:'">
         <xsl:element
            name="{if (current-grouping-key() = $schematron-role) then $docbook-alert[index-of($schematron-role,current-grouping-key())] else 'caution'}"
            namespace="http://docbook.org/ns/docbook">
            <itemizedlist>
               <xsl:for-each select="current-group()">
                  <listitem>
                     <para>
                        <xsl:choose>
                           <xsl:when test="current-grouping-key() = 'info'">
                              <xsl:copy-of
                                 select="tan:prep-string-for-docbook(normalize-space(comment()))"/>
                           </xsl:when>
                           <xsl:when test="@id = 'attr-ids'">
                              <xsl:variable name="message" as="xs:string"
                                 select="concat('Must point to @xml:id value of ', $lt, $id-idrefs//tan:id[tan:idrefs/@attribute = $element-or-attribute-name]/@element, '>')"/>
                              <xsl:copy-of select="tan:prep-string-for-docbook($message)"/>
                           </xsl:when>
                           <xsl:otherwise>
                              <xsl:variable name="rule"
                                 select="
                                    (comment(),
                                    replace(string-join(for $i in text()
                                    return
                                       normalize-space($i)), '\s*\(.*\)', ''))[1]"/>
                              <xsl:variable name="global-var-check"
                                 select="analyze-string($rule, '\$[-\w]+')"/>
                              <xsl:copy-of select="tan:prep-string-for-docbook($rule)"/>
                           </xsl:otherwise>
                        </xsl:choose>
                     </para>
                  </listitem>
               </xsl:for-each>
            </itemizedlist>
         </xsl:element>
      </xsl:for-each-group>
      <xsl:for-each
         select="
            $these-rules/sqf:fix[if (@use-when) then
               matches(@use-when, $element-or-attribute-name)
            else
               true()][not(tokenize(@tan:does-not-apply-to, '\s+') = $element-or-attribute-name)]">
         <tip>
            <para>
               <emphasis role="bold">
                  <xsl:text>Schematron Quick Fix: </xsl:text>
                  <xsl:value-of select="sqf:description/sqf:title"/>
                  <xsl:text> </xsl:text>
               </emphasis>
               <xsl:copy-of
                  select="
                     for $i in sqf:description/sqf:p
                     return
                        tan:prep-string-for-docbook($i)"
               />
            </para>
         </tip>
      </xsl:for-each>
   </xsl:template>

   <!-- Function for examples -->
   <xsl:function name="tan:examples" as="element()*">
      <xsl:param name="element-or-attribute-name" as="xs:string?"/>
      <xsl:param name="is-attribute" as="xs:boolean?"/>
      <xsl:variable name="example-elements" as="element()*"
         select="
            if ($is-attribute = true()) then
               $ex-collection//@*[name(.) = $element-or-attribute-name]/..
            else
               $ex-collection//*[name(.) = $element-or-attribute-name][not(self::tei:l)] (: the not(@part) is a hack to avoid having tan:l match tei:l :)"/>
      <xsl:for-each-group select="$example-elements[position() le $max-examples]" group-by="root(.)">
         <!--<xsl:variable name="parent" select="current-grouping-key()" as="element()"/>-->
         <xsl:variable name="text" select="tan:element-to-example-text(current-group())"/>
         <xsl:variable name="text-to-emphasize"
            select="concat('\s', $element-or-attribute-name, '=&quot;[^&quot;]+&quot;|&lt;/?', $element-or-attribute-name, '(/?>|\s+[^&gt;]*>)')"/>
         <xsl:variable name="text-emphasized" select="analyze-string($text, $text-to-emphasize)"/>
         <example>
            <title>
               <code>
                  <xsl:value-of
                     select="
                        if ($is-attribute = true()) then
                           '@'
                        else
                           '&lt;'"/>
                  <xsl:value-of select="$element-or-attribute-name"/>
                  <xsl:value-of
                     select="
                        if ($is-attribute) then
                           ()
                        else
                           '>'"
                  />
               </code>
            </title>
            <programlisting><xsl:apply-templates select="$text-emphasized" mode="emph-string-for-docbook"/></programlisting>
         </example>
      </xsl:for-each-group>
   </xsl:function>
   <xsl:template match="fn:match" mode="emph-string-for-docbook" as="element()">
      <emphasis role="bold">
         <xsl:value-of select="."/>
      </emphasis>
   </xsl:template>
   <xsl:function name="tan:element-to-example-text" as="xs:string?">
      <xsl:param name="example-elements" as="element()*"/>
      <xsl:variable name="lca-element" as="element()?" select="tan:lca($example-elements)"/>
      <xsl:variable name="context-element"
         select="
            if (deep-equal(root($lca-element), $lca-element/..)) then
               $lca-element
            else
               $lca-element/.."/>
      <xsl:variable name="raw" as="xs:string*">
         <xsl:apply-templates mode="tree-to-text" select="$context-element">
            <xsl:with-param name="example-elements" select="$example-elements"/>
         </xsl:apply-templates>
      </xsl:variable>
      <xsl:value-of select="string-join($raw, '')"/>
   </xsl:function>

   <!-- tree-to-text template -->
   <xsl:template match="*" mode="tree-to-text" as="xs:string*">
      <xsl:param name="example-elements" as="element()*"/>
      <xsl:variable name="this-element" select="."/>
      <xsl:choose>
         <xsl:when test="descendant::*[. = $example-elements]">
            <xsl:value-of select="tan:first-tag-to-text(.)"/>
            <xsl:apply-templates mode="tree-to-text" select="*">
               <xsl:with-param name="example-elements" select="$example-elements"/>
            </xsl:apply-templates>
            <xsl:value-of select="tan:last-tag-to-text(.)"/>
         </xsl:when>
         <xsl:when test=". = $example-elements">
            <xsl:value-of select="tan:first-tag-to-text(.)"/>
            <xsl:apply-templates mode="tree-to-text" select="*">
               <xsl:with-param name="example-elements" select="$example-elements"/>
            </xsl:apply-templates>
            <xsl:if test="text() | *">
               <xsl:value-of select="tan:last-tag-to-text(.)"/>
            </xsl:if>
         </xsl:when>
         <xsl:when test=".. = $example-elements and position() le $qty-contextual-children">
            <xsl:value-of select="tan:shallow-copy(.)"/>
         </xsl:when>
         <xsl:when test=".. = $example-elements and position() = $qty-contextual-children + 1">
            <xsl:value-of select="concat(tan:indent(.), $ellipses)"/>
         </xsl:when>
         <xsl:when
            test="
               for $i in (1 to $qty-contextual-siblings)
               return
                  ((preceding-sibling::*[$i],
                  following-sibling::*[$i]) = $example-elements)">
            <xsl:value-of select="tan:shallow-copy(.)"/>
         </xsl:when>
         <xsl:when
            test="
               (preceding-sibling::*[$qty-contextual-siblings + 1],
               following-sibling::*[$qty-contextual-siblings + 1]) = $example-elements">
            <xsl:value-of select="concat(tan:indent(.), $ellipses)"/>
         </xsl:when>
      </xsl:choose>
   </xsl:template>
   <xsl:template match="@*" mode="tree-to-text" as="xs:string?">
      <xsl:value-of select="concat(' ', name(.), '=&quot;', ., '&quot;')"/>
   </xsl:template>
   <xsl:template match="text()"/>

   <!-- Functions to turn nodes into printable text, indented -->
   <xsl:function name="tan:indent" as="xs:string?">
      <xsl:param name="element" as="element()?"/>
      <xsl:value-of
         select="
            string-join(
            for $i in (1 to count($element/ancestor::*))
            return
               $indent)"
      />
   </xsl:function>
   <xsl:function name="tan:first-tag-to-text" as="xs:string?">
      <xsl:param name="element" as="element()?"/>
      <xsl:variable name="raw" as="xs:string*">
         <xsl:value-of select="concat(tan:indent($element), '&lt;', name($element))"/>
         <xsl:apply-templates select="$element/@*" mode="tree-to-text"/>
         <xsl:choose>
            <xsl:when test="$element/child::*">
               <!-- element has children -->
               <xsl:text>>&#xA;</xsl:text>
            </xsl:when>
            <xsl:when test="$element/text()">
               <!-- element has no children, but does have text -->
               <xsl:text>></xsl:text>
               <xsl:value-of select="$element/text()"/>
            </xsl:when>
            <xsl:otherwise>
               <!-- empty element -->
               <xsl:text>/>&#xA;</xsl:text>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:value-of select="string-join($raw)"/>
   </xsl:function>
   <xsl:function name="tan:last-tag-to-text" as="xs:string?">
      <xsl:param name="element" as="element()?"/>
      <xsl:value-of
         select="
            concat(if ($element/*) then
               tan:indent($element)
            else
               (), '&lt;/', name($element), '>&#xA;')"
      />
   </xsl:function>
   <xsl:function name="tan:shallow-copy" as="xs:string?">
      <xsl:param name="element" as="element()?"/>
      <xsl:variable name="raw" as="xs:string*">
         <xsl:value-of select="tan:first-tag-to-text($element)"/>
         <xsl:if test="$element/*">
            <xsl:value-of select="tan:indent($element/*[1])"/>
            <xsl:value-of select="$ellipses"/>
         </xsl:if>
         <xsl:if test="$element/(*, text())">
            <xsl:value-of select="tan:last-tag-to-text($element)"/>
         </xsl:if>
      </xsl:variable>
      <xsl:value-of select="string-join($raw)"/>
   </xsl:function>

   <!--<xsl:function name="tan:tag-codes" as="item()*">
      <xsl:param name="text" as="xs:string?"/>
      <xsl:variable name="code-check" select="analyze-string($text, '&lt;[^>]+>|@[-:\w]+')"/>
      <xsl:for-each select="$code-check/*">
         <xsl:choose>
            <xsl:when test="self::fn:non-match">
               <xsl:value-of select="."/>
            </xsl:when>
            <xsl:when test="self::fn:match and matches(., '^@')">
               <xsl:variable name="this-attr" select="replace(., '^@', '')"/>
               <code>
                  <xsl:text>@</xsl:text>
                  <link linkend="{concat('attribute-',replace($this-attr,':',''))}">
                     <xsl:value-of select="$this-attr"/>
                  </link>
               </code>
            </xsl:when>
            <xsl:otherwise>
               <xsl:variable name="this-el" select="replace(., '[&lt;>]', '')"/>
               <code>
                  <xsl:text>&lt;</xsl:text>
                  <link linkend="{concat('element-',$this-el)}">
                     <xsl:value-of select="$this-el"/>
                  </link>
                  <xsl:text>></xsl:text>
               </code>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>
   </xsl:function>-->
   <!--<xsl:function name="tan:get-parent-element-names" as="xs:string*">
      <xsl:param name="self-name" as="xs:string"/>
      <xsl:copy-of
         select="
            tan:get-parent-elements($rng-collection-without-TEI//(rng:element,
            rng:attribute)[@name = $self-name]//(ancestor::rng:define,
            ancestor::rng:element)[last()])"
      />
   </xsl:function>-->
   <xsl:function name="tan:get-parent-elements" as="element()*">
      <xsl:param name="current-elements" as="element()*"/>
      <xsl:variable name="elements-to-define" select="$current-elements[self::rng:define]"/>
      <xsl:choose>
         <xsl:when test="exists($elements-to-define)">
            <xsl:variable name="new-elements"
               select="
                  for $i in $elements-to-define/@name
                  return
                     $rng-collection-without-TEI//rng:ref[@name = $i]//(ancestor::rng:define,
                     ancestor::rng:element)[last()]"/>
            <xsl:copy-of
               select="
                  tan:get-parent-elements((($current-elements except $current-elements[name(.) = 'define']),
                  $new-elements))"
            />
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of select="$current-elements"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   <!--<xsl:function name="tan:normalize-string-sequence" as="xs:string?">
      <xsl:param name="input-text-strings" as="xs:string*"/>
      <xsl:variable name="raw-joined" select="string-join($input-text-strings, ' ')"/>
      <xsl:variable name="strip-trailing-spaces"
         select="replace($raw-joined, '([\(@&lt;])\s+', '$1')"/>
      <xsl:variable name="strip-preceding-spaces"
         select="replace($strip-trailing-spaces, '\s+([\),\?>*+])', '$1')"/>
      <xsl:variable name="add-trailing-spaces"
         select="replace($strip-preceding-spaces, '([,])', '$1 ')"/>
      <xsl:variable name="add-preceding-spaces"
         select="replace($add-trailing-spaces, '([ ])', ' $1')"/>
      <xsl:variable name="final" select="$add-preceding-spaces"/>
      <xsl:value-of select="normalize-space($final)"/>
   </xsl:function>-->
   <xsl:function name="tan:lca" as="node()?">
      <xsl:param name="pSet" as="node()*"/>
      <xsl:sequence
         select="
            if (not($pSet))
            then
               ()
            else
               if (not($pSet[2]))
               then
                  $pSet[1]
               else
                  if ($pSet intersect $pSet/ancestor::node())
                  then
                     tan:lca($pSet[not($pSet intersect ancestor::node())])
                  else
                     tan:lca($pSet/..)"
      />
   </xsl:function>

   <xsl:template match="*" mode="prep-items-for-docbook">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="text()" mode="prep-items-for-docbook">
      <xsl:copy-of select="tan:prep-string-for-docbook(.)"/>
   </xsl:template>
   <xsl:function name="tan:prep-string-for-docbook" as="item()*">
      <xsl:param name="para-text" as="xs:string?"/>
      <xsl:variable name="pass-1" as="item()*">
         <xsl:variable name="variable-check" select="analyze-string($para-text, '\$[-\w]+')"/>
         <xsl:apply-templates select="$variable-check" mode="itemize-param-string-for-docbook"/>
      </xsl:variable>
      <xsl:variable name="pass-2" as="item()*">
         <xsl:apply-templates select="$pass-1" mode="code-nodes"/>
      </xsl:variable>
      <xsl:variable name="pass-3" as="item()*">
         <xsl:apply-templates select="$pass-2" mode="add-xrefs"/>
      </xsl:variable>
      <xsl:copy-of select="$pass-3"/>
   </xsl:function>

   <xsl:template match="*" mode="code-nodes add-xrefs">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="text()" mode="code-nodes">
      <xsl:variable name="element-and-attribute-check"
         select="analyze-string(., concat($lt, '[-:\w+]+>|@[-:\w+]+'))"/>
      <!--<xsl:apply-templates select="$element-and-attribute-check"
         mode="code-and-link-element-and-attribute-string-for-docbook"/>-->
      <xsl:for-each select="$element-and-attribute-check/*">
         <xsl:choose>
            <xsl:when test="self::fn:match">
               <xsl:call-template name="code-and-link-element-and-attribute-string-for-docbook">
                  <xsl:with-param name="input-string" select="."/>
               </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
               <xsl:value-of select="text()"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>
   </xsl:template>
   <xsl:template match="text()" mode="add-xrefs">
      <xsl:variable name="xref-check" select="analyze-string(., 'main\.xml#[-_\w]+|iris\.xml')"/>
      <xsl:apply-templates select="$xref-check" mode="xref-for-docbook"/>
   </xsl:template>

   <!-- templates applied to the result of analyze-string() -->
   <xsl:template match="fn:match" mode="itemize-param-string-for-docbook">
      <xsl:variable name="list" as="xs:string*">
         <xsl:choose>
            <xsl:when test=". = '$tokenization-errors'">
               <xsl:sequence select="$tokenization-errors"/>
            </xsl:when>
            <xsl:when test=". = '$inclusion-errors'">
               <xsl:sequence select="$inclusion-errors"/>
            </xsl:when>
            <xsl:when test=". = '$relationship-keywords-for-tan-versions'">
               <xsl:sequence select="$relationship-keywords-for-tan-versions"/>
            </xsl:when>
            <xsl:when test=". = '$relationship-keywords-for-tan-editions'">
               <xsl:sequence select="$relationship-keywords-for-tan-editions"/>
            </xsl:when>
            <xsl:when test=". = '$relationship-keywords-for-class-1-editions'">
               <xsl:sequence select="$relationship-keywords-for-class-1-editions"/>
            </xsl:when>
            <xsl:when test=". = '$relationship-keywords-for-tan-files'">
               <xsl:sequence select="$relationship-keywords-for-tan-files"/>
            </xsl:when>
            <xsl:when test=". = '$relationship-keywords-all'">
               <xsl:sequence select="$relationship-keywords-all"/>
            </xsl:when>
            <xsl:when test=". = '$schema-version-major'">
               <xsl:sequence select="string($schema-version-major)"/>
            </xsl:when>
            <xsl:when test=". = '$schema-version-minor'">
               <xsl:sequence select="$schema-version-minor"/>
            </xsl:when>
         </xsl:choose>
      </xsl:variable>
      <xsl:copy-of select="tan:string-sequence-to-docbook-itemizedlist($list)"/>
   </xsl:template>
   <xsl:function name="tan:string-sequence-to-docbook-itemizedlist" as="element()?">
      <xsl:param name="string-sequence" as="xs:string*"/>
      <itemizedlist>
         <xsl:for-each select="$string-sequence">
            <listitem>
               <para>
                  <xsl:value-of select="."/>
               </para>
            </listitem>
         </xsl:for-each>
      </itemizedlist>
   </xsl:function>
   <xsl:template name="code-and-link-element-and-attribute-string-for-docbook" as="item()*">
      <xsl:param name="input-string" as="xs:string?"/>
      <xsl:variable name="is-attribute"
         select="
            if (starts-with($input-string, '@')) then
               true()
            else
               false()"/>
      <xsl:variable name="linkend"
         select="
            concat(if ($is-attribute = true()) then
               'attribute'
            else
               'element', '-', replace($input-string, '[&lt;@>:]', ''))"/>
      <code>
         <link linkend="{$linkend}">
            <xsl:value-of select="$input-string"/>
         </link>
      </code>
   </xsl:template>
   <xsl:template match="fn:match" mode="xref-for-docbook" as="item()*">
      <xsl:choose>
         <xsl:when test="starts-with(., 'main')">
            <xref linkend="{replace(.,'main\.xml#','')}"/>
         </xsl:when>
         <xsl:when test="starts-with(., 'iris')">
            <link xlink:href="iris.xml">IRIs.xml</link>
         </xsl:when>
      </xsl:choose>
   </xsl:template>

   <xsl:template match="tan:section"/>

</xsl:stylesheet>
