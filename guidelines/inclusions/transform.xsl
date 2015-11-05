<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math"
   xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns="http://docbook.org/ns/docbook"
   xmlns:saxon="http://icl.com/saxon" xmlns:lxslt="http://xml.apache.org/xslt"
   xmlns:redirect="http://xml.apache.org/xalan/redirect" xmlns:exsl="http://exslt.org/common"
   xmlns:doc="http://nwalsh.com/xsl/documentation/1.0" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:tei="http://www.tei-c.org/ns/1.0" 
   xmlns:rng="http://relaxng.org/ns/structure/1.0" xmlns:sch="http://purl.oclc.org/dsdl/schematron"
   xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:a="http://relaxng.org/ns/compatibility/annotations/1.0"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
   extension-element-prefixes="saxon redirect lxslt exsl"
   exclude-result-prefixes="xs math xd saxon lxslt redirect exsl doc" version="3.0">
   <xd:doc scope="stylesheet">
      <xd:desc>
         <xd:p><xd:b>Updated </xd:b> Oct 27, 2015</xd:p>
         <xd:p>Stylesheet applied to master-list.xml, to transform all the TAN schema files into a
            series of Docbook inclusions for the TAN guidelines, documenting the structural rules,
            the validation rules, the schematron quick fixes.</xd:p>
      </xd:desc>
   </xd:doc>
   <xsl:output method="xml" indent="no"/>

   <xsl:include href="../../functions/TAN-parameters.xsl"/>
   <xsl:param name="indent-value" select="3"/>
   <xsl:param name="max-examples" select="4"/>
   <xsl:param name="qty-contextual-selves" select="3"/>
   <xsl:param name="qty-contextual-siblings" select="1"/>
   <xsl:param name="qty-contextual-children" select="3"/>
   <xsl:param name="schematron-role"
      select="('warn', 'warning', 'fatal', 'error', 'info', 'information')"/>
   <xsl:param name="docbook-alert"
      select="('important', 'important', 'warning', 'warning', 'note', 'note')"/>

   <xsl:variable name="sequence" select="//tan:section/@which"/>
   <!--<xsl:variable name="string-delimiter" select="concat('\s*(*', $apos, ',?\s*', $apos, '?)*|,',$lf,'\s+')"/>-->
   <xsl:variable name="string-delimiter" select="concat('\(',$apos,'?|',$apos,'?,\s+',$apos,'?|',$apos,'?\)|^',$apos,'|',$apos,'$')"/>

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
   <xsl:variable name="ellipses" select="'...........&#xA;'"/>

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
         <xsl:variable name="these-element-summaries">
            <xsl:apply-templates select="$this//rng:element">
               <xsl:sort select="lower-case(@name)"/>
            </xsl:apply-templates>
         </xsl:variable>
         <xsl:variable name="these-attribute-summaries">
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
                  <para>No attributes or elements are defined specifically for <xsl:value-of
                        select="$this-name"/>.</para>
               </xsl:if>
            </section>
         </xsl:result-document>
      </xsl:for-each>
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
      <xsl:variable name="prefix"
         select="
            if (name() = 'element') then
               '&lt;'
            else
               '@'"/>
      <xsl:variable name="suffix"
         select="
            if (name() = 'element') then
               '>'
            else
               ''"/>
      <section xml:id="{concat(name(.),'-',replace($this-name,':',''))}">
         <title>
            <code>
               <xsl:value-of select="$prefix"/>
               <xsl:value-of select="$this-name"/>
               <xsl:value-of select="$suffix"/>
            </code>
         </title>
         <xsl:apply-templates select="a:documentation"/>
         <xsl:variable name="formaldef" as="item()*">
            <xsl:variable name="raw" as="item()*">
               <xsl:choose>
                  <xsl:when test="rng:*">
                     <xsl:apply-templates select="rng:*" mode="formaldef"/>
                  </xsl:when>
                  <xsl:otherwise>
                     <!-- for attributes that are not defined, i.e., text -->
                     <xsl:text>text</xsl:text>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:variable>
            <!--<xsl:value-of select="tan:normalize-string-sequence($raw)"/>-->
            <xsl:copy-of select="$raw"/>
         </xsl:variable>
         <para>
            <xsl:text>Definition: </xsl:text>
            <code>
               <xsl:copy-of select="$formaldef"/>
            </code>
         </para>
         <para>
            <xsl:text>Used by: </xsl:text>
            <xsl:choose>
               <xsl:when test="exists($this-parents)">
                  <xsl:for-each
                     select="
                        $this-parents
                        ">
                     <xsl:sort select="@name"/>
                     <code>
                        <xref linkend="{concat('element-',@name)}"/>
                     </code>
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
         <!--<xsl:call-template name="examples">
            <xsl:with-param name="element-or-attribute-name" select="$this-name"/>
            <xsl:with-param name="is-attribute" select="$is-attribute"/>
         </xsl:call-template>-->
      </section>
   </xsl:template>

   <!-- Template for the main description -->
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
         <xsl:sequence select="tan:tag-codes(.)"/>
      </para>
   </xsl:template>

   <!-- Templates for the formal (terse) definition -->
   <xsl:template match="rng:optional" mode="formaldef">
      <xsl:apply-templates mode="formaldef"/>
      <xsl:text>?</xsl:text>
      <xsl:call-template name="comma-check"/>
   </xsl:template>
   <xsl:template match="rng:zeroOrMore" mode="formaldef">
      <xsl:apply-templates mode="formaldef"/>
      <xsl:text>*</xsl:text>
      <xsl:call-template name="comma-check"/>
   </xsl:template>
   <xsl:template match="rng:oneOrMore" mode="formaldef">
      <xsl:apply-templates mode="formaldef"/>
      <xsl:text>+</xsl:text>
      <xsl:call-template name="comma-check"/>
   </xsl:template>
   <xsl:template match="rng:choice | rng:group | rng:interleave" mode="formaldef">
      <xsl:text>(</xsl:text>
      <xsl:apply-templates mode="formaldef"/>
      <xsl:text>)</xsl:text>
      <xsl:call-template name="comma-check"/>
   </xsl:template>
   <xsl:template match="rng:ref" mode="formaldef">
      <xsl:variable name="name" select="@name"/>
      <xsl:variable name="defs"
         select="$rng-collection-without-TEI//rng:define[@name = $name][not(rng:empty)]"/>
      <xsl:if test="parent::rng:choice and preceding-sibling::rng:ref">|</xsl:if>
      <!--<xsl:value-of select="@name"/>-->
      <xsl:if test="count($defs) gt 1">
         <xsl:text>[[</xsl:text>
      </xsl:if>
      <xsl:for-each select="$defs">
         <xsl:if test="count($defs) gt 1">
            <xsl:text> {</xsl:text>
            <xsl:value-of select="replace(base-uri(.), '.+/(.+)', '$1')"/>
            <xsl:text>:} </xsl:text>
         </xsl:if>
         <xsl:apply-templates select="." mode="formaldef"/>
         <xsl:if test="position() lt last()">
            <xsl:text> OR </xsl:text>
         </xsl:if>
      </xsl:for-each>
      <xsl:if test="count($defs) gt 1">
         <xsl:text>]]</xsl:text>
      </xsl:if>
      <xsl:call-template name="comma-check"/>
   </xsl:template>
   <xsl:template match="rng:define[count(rng:*) gt 1]" mode="formaldef">
      <xsl:text>(</xsl:text>
      <xsl:apply-templates select="rng:*" mode="formaldef"/>
      <xsl:text>)</xsl:text>
   </xsl:template>
   <xsl:template match="rng:define[count(rng:*) le 1]" mode="formaldef">
      <xsl:apply-templates select="rng:*" mode="formaldef"/>
   </xsl:template>
   <xsl:template match="rng:element" mode="formaldef">
      <xsl:text>&lt;</xsl:text>
      <link linkend="{concat('element-',replace(@name,':',''))}">
         <xsl:value-of select="@name"/>
      </link>
      <xsl:text>&gt;</xsl:text>
      <!--<xref linkend="{concat('element-',@name)}"/>-->
      <!--<xsl:apply-templates mode="formaldef"/>-->
      <xsl:call-template name="comma-check"/>
   </xsl:template>
   <xsl:template match="rng:attribute" mode="formaldef">
      <xsl:text>@</xsl:text>
      <link linkend="{concat('attribute-',replace(@name,':',''))}">
         <xsl:value-of select="@name"/>
      </link>
      <!--<xref linkend="{concat('attribute-',@name)}"/>-->
      <!--<xsl:apply-templates mode="formaldef"/>-->
      <xsl:call-template name="comma-check"/>
   </xsl:template>
   <xsl:template match="rng:param" mode="formaldef">
      <xsl:text>(</xsl:text>
      <xsl:value-of select="@name"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="."/>
      <xsl:text>)</xsl:text>
   </xsl:template>
   <xsl:template match="rng:data" mode="formaldef">
      <xsl:value-of select="@type"/>
      <xsl:text> </xsl:text>
      <xsl:apply-templates mode="formaldef"/>
   </xsl:template>
   <xsl:template match="rng:text" mode="formaldef">
      <xsl:text>text</xsl:text>
   </xsl:template>
   <xsl:template match="text() | rng:empty" mode="formaldef"/>
   <xsl:template name="comma-check">
      <xsl:choose>
         <xsl:when test="parent::rng:choice and following-sibling::rng:*">
            <xsl:text> | </xsl:text>
         </xsl:when>
         <xsl:when test="parent::rng:interleave and following-sibling::rng:*">
            <xsl:text> &amp; </xsl:text>
         </xsl:when>
         <xsl:when test="following-sibling::rng:*">
            <xsl:text>, </xsl:text>
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
               concat('tan:', $element-or-attribute-name, '[^-\w]|tan:', $element-or-attribute-name, '$')"
      />
      <xsl:variable name="these-rules"
         select="$sch-collection//sch:rule[matches(@context, $search-string) or tokenize(@tan:applies-to, '\s+') = $element-or-attribute-name]"/>
      <xsl:for-each-group
         select="$these-rules/(sch:report, sch:assert)[not(@test = ('false()', 'true()'))][not(tokenize(@tan:does-not-apply-to, '\s+') = $element-or-attribute-name)], $sch-collection//(sch:report, sch:assert)[tokenize(@tan:applies-to,'\s+') = $element-or-attribute-name]"
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
                              <xsl:value-of select="comment()"/>
                           </xsl:when>
                           <xsl:when test="@id = 'attr-ids'">
                              <xsl:variable name="attribute-key"
                                 select="index-of(tokenize(preceding-sibling::sch:let[@name = 'referring-attribute']/@value, '[^-\w]+'), $element-or-attribute-name)"/>
                              <xsl:variable name="target-element"
                                 select="tokenize(preceding-sibling::sch:let[@name = 'referred-element']/@value, '[^-\w]+')[$attribute-key]"/>
                              <xsl:text>Must point to @xml:id value of </xsl:text>
                              <xsl:value-of select="$target-element"/>
                           </xsl:when>
                           <xsl:when test="@id = 'tokenization-errors'">
                              <xsl:variable name="errors"
                                 select="tan:resolve-global-parameters('$tokenization-errors')"/>
                              <xsl:text>Common tokenization errors: </xsl:text>
                              <itemizedlist>
                                 <xsl:for-each select="tokenize($errors,' ')">
                                    <listitem>
                                       <para>
                                          <xsl:value-of select="."/>
                                       </para>
                                    </listitem>
                                 </xsl:for-each>
                              </itemizedlist>
                           </xsl:when>
                           <xsl:otherwise>
                              <xsl:variable name="rule" select="(comment(),
                                 replace(string-join(for $i in text()
                                 return
                                 normalize-space($i)), '\s*\(.*\)', ''))[1]"/>
                              <xsl:variable name="global-var-check" select="analyze-string($rule,'\$[-\w]+')"/>
                              <xsl:for-each select="$global-var-check/*">
                                 <xsl:choose>
                                    <xsl:when test="self::fn:match">
                                       <xsl:variable name="this-var-res" select="tokenize(tan:resolve-global-parameters(.),'[\n\r]+')"/>
                                       <xsl:choose>
                                          <xsl:when test="count($this-var-res) = 1">
                                             <xsl:value-of select="$this-var-res"/>
                                          </xsl:when>
                                          <xsl:otherwise>
                                             <itemizedlist>
                                                <xsl:for-each select="$this-var-res[matches(.,'\w')]">
                                                   <listitem><para>
                                                      <xsl:value-of select="."/>
                                                   </para></listitem>
                                                </xsl:for-each>
                                             </itemizedlist>
                                          </xsl:otherwise>
                                       </xsl:choose>
                                    </xsl:when>
                                    <xsl:otherwise>
                                       <xsl:value-of select="."/>
                                    </xsl:otherwise>
                                 </xsl:choose>
                              </xsl:for-each>
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
               <xsl:value-of select="tan:resolve-global-parameters(sqf:description/sqf:p)"/>
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
               $ex-collection//*[name(.) = $element-or-attribute-name][not(self::tei:l)] (: the not(@part) is a hack to avoid having tan:l match tei:l :)"
      />
      <xsl:for-each-group select="$example-elements[position() le $max-examples]" group-by="root(.)">
         <!--<xsl:variable name="parent" select="current-grouping-key()" as="element()"/>-->
         <xsl:variable name="text" select="tan:element-to-example-text(current-group())"/>
         <xsl:variable name="text-to-emphasize"
            select="concat('\s', $element-or-attribute-name, '=&quot;[^&quot;]+&quot;|&lt;/?', $element-or-attribute-name, '(/?>|\s+[^&gt;]*>)')"/>
         <xsl:variable name="text-emphasized" select="analyze-string($text, $text-to-emphasize)"/>
         <xsl:element name="example" namespace="http://docbook.org/ns/docbook" >
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
            <programlisting>
                    <!--<xsl:value-of select="$ellipses"/>-->
               <xsl:apply-templates select="$text-emphasized" mode="code-analyze-string"/>
               <!--<xsl:value-of select="$text"/>-->
                    <!--<xsl:text>...........</xsl:text>-->
                </programlisting>
         </xsl:element>
      </xsl:for-each-group>
   </xsl:function>
   <xsl:template match="fn:match" mode="code-analyze-string" as="element()">
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
               $lca-element/.."
      />
      <xsl:variable name="raw" as="xs:string*">
         <xsl:apply-templates mode="tree-to-text" select="$context-element">
            <xsl:with-param name="example-elements" select="$example-elements"/>
         </xsl:apply-templates>
      </xsl:variable>
      <xsl:value-of select="string-join($raw,'')"/>
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
   <xsl:template match="text()"></xsl:template>

   <!-- Functions to turn nodes into printable text, indented -->
   <xsl:function name="tan:indent" as="xs:string?">
      <xsl:param name="element" as="element()?"/>
      <xsl:variable name="indent-check" select="count($element/ancestor::*) * $indent-value"/>
      <xsl:value-of
         select="
            string-join(
            for $i in (1 to $indent-check)
            return
               ' ')"
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

   <xsl:function name="tan:tag-codes" as="item()*">
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
   </xsl:function>
   <xsl:function name="tan:get-parent-element-names" as="xs:string*">
      <xsl:param name="self-name" as="xs:string"/>
      <xsl:copy-of
         select="
            tan:get-parent-elements($rng-collection-without-TEI//(rng:element,
            rng:attribute)[@name = $self-name]//(ancestor::rng:define,
            ancestor::rng:element)[last()])"
      />
   </xsl:function>
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
   <xsl:function name="tan:resolve-global-parameters" as="xs:string*">
      <xsl:param name="string" as="xs:string?"/>
      <xsl:variable name="raw1" select="analyze-string($string, '\$[-\w]+')"/>
      <xsl:variable name="raw2">
         <xsl:for-each select="$raw1/*">
            <xsl:choose>
               <xsl:when test="self::fn:non-match">
                  <xsl:value-of select="."/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:variable name="variable-meaning-separators"
                     select="analyze-string($fn-collection//xsl:variable[@name = replace(current(), '^\$', '')]/@select, $string-delimiter)"/>
                  <xsl:for-each select="$variable-meaning-separators/*">
                     <xsl:choose>
                        <xsl:when test="self::fn:non-match">
                           <xsl:value-of
                              select="
                                 if (matches(., '\$')) then
                                    (tan:resolve-global-parameters(.))
                                 else
                                    ."
                           />
                        </xsl:when>
                        <xsl:otherwise>
                           <xsl:value-of select="$lf"/>
                        </xsl:otherwise>
                     </xsl:choose>
                  </xsl:for-each>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each>
      </xsl:variable>
      <xsl:value-of select="$raw2"/>
   </xsl:function>
   <!-- placed here to suppress warning message -->
   <xsl:template match="tan:component"/>
</xsl:stylesheet>
