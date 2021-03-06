<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="tag:textalign.net,2015:ns" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:functx="http://www.functx.com"
   xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:sch="http://purl.oclc.org/dsdl/schematron"
   exclude-result-prefixes="#all" version="2.0">
   <xd:doc scope="stylesheet">
      <xd:desc>
         <xd:p><xd:b>Updated </xd:b>March 11, 2017</xd:p>
         <xd:p>Variables, functions, and templates for marking errors in TAN files. To be used in
            conjunction with TAN-core-functions.xsl. Includes items related to help requests.</xd:p>
      </xd:desc>
   </xd:doc>

   <xsl:variable name="errors" select="doc('TAN-errors.xml')"/>
   <xsl:function name="tan:fix" as="element()?">
      <!-- Input: any items; a string representing a fix type -->
      <!-- Ouput: a tan:fix element with @type -->
      <!-- This function is used to populate a file with material to be used by Schematron Quick Fixes -->
      <xsl:param name="fix" as="item()*"/>
      <xsl:param name="fix-type" as="xs:string?"/>
      <xsl:if test="string-length($fix-type) gt 0">
         <fix type="{$fix-type}">
            <xsl:copy-of select="$fix"/>
         </fix>
      </xsl:if>
   </xsl:function>
   <xsl:function name="tan:error" as="element()?">
      <!-- one-parameter function of the master version, below -->
      <xsl:param name="idref" as="xs:string"/>
      <xsl:copy-of select="tan:error($idref, (), (), ())"/>
   </xsl:function>
   <xsl:function name="tan:error" as="element()?">
      <!-- two-parameter function of the master version, below -->
      <xsl:param name="idref" as="xs:string"/>
      <xsl:param name="diagnostic-message" as="item()*"/>
      <xsl:copy-of select="tan:error($idref, $diagnostic-message, (), ())"/>
   </xsl:function>
   <xsl:function name="tan:error" as="element()?">
      <!-- Input: idref of an error, and optional diagnostic messages
         Output: the appropriate <error> with each diagnostic inserted as a child <message>
      -->
      <xsl:param name="idref" as="xs:string"/>
      <xsl:param name="diagnostic-message" as="item()*"/>
      <xsl:param name="fix" as="item()*"/>
      <xsl:param name="fix-type" as="xs:string?"/>
      <xsl:variable name="this-error" select="$errors//id($idref)"/>
      <xsl:for-each select="$this-error">
         <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:copy-of select="*"/>
            <xsl:for-each select="$diagnostic-message">
               <message>
                  <xsl:value-of select="."/>
               </message>
            </xsl:for-each>
            <xsl:copy-of select="tan:fix($fix, $fix-type)"/>
         </xsl:copy>
      </xsl:for-each>
   </xsl:function>
   <xsl:function name="tan:error-report" as="xs:string*">
      <!-- Input: strings corresponding to an error id or tan:error elements 
      Output: a sequence of strings constituting a report to the user -->
      <xsl:param name="error" as="item()*"/>
      <xsl:variable name="error-element" as="element()*">
         <xsl:for-each select="$error">
            <xsl:choose>
               <xsl:when test=". instance of xs:string">
                  <!-- assumes that the string is an error id -->
                  <xsl:copy-of select="tan:error(.)"/>
               </xsl:when>
               <xsl:when test="self::tan:error">
                  <xsl:copy-of select="."/>
               </xsl:when>
            </xsl:choose>
         </xsl:for-each>
      </xsl:variable>
      <xsl:for-each select="$error-element">
         <xsl:variable name="this-message"
            select="
               if (exists(tan:message)) then
                  concat(' (', string-join(tan:message, '; '), ')')
               else
                  ()"/>
         <xsl:value-of select="concat('[', @xml:id, '] ', *[1], $this-message)"/>
      </xsl:for-each>
   </xsl:function>
   <xsl:variable name="all-function-uses-of-error"
      select="$all-functions//*[matches(@select, concat('tan:error\([', $quot, $apos, ']'))]"/>
   <xsl:variable name="function-error-ids"
      select="
         for $i in $all-function-uses-of-error/@select
         return
            replace($i, concat('.*tan:error\([', $apos, $quot, '](\w+).+'), '$1')"/>
   <xsl:variable name="all-schema-uses-of-error"
      select="
         $all-schemas/sch:*//*[some $i in @*
            satisfies matches($i, 'tan:error\(')]"/>
   <xsl:variable name="schema-error-ids"
      select="
         for $i in $all-schema-uses-of-error/(@select, @value)[matches(., 'tan:error\(')]
         return
            replace($i, concat('.*tan:error\([', $apos, $quot, '](\w+).+'), '$1')"/>
   <xsl:variable name="errors-not-used"
      select="$errors//tan:error[not(@xml:id = ($function-error-ids, $schema-error-ids))]"/>


   <xsl:param name="help-trigger" select="'???'"/>
   <xsl:variable name="help-trigger-regex" select="tan:escape($help-trigger)"/>
   <xsl:function name="tan:help" as="element()">
      <xsl:param name="diagnostic-message" as="item()*"/>
      <xsl:param name="fix" as="item()*"/>
      <xsl:param name="fix-type" as="xs:string?"/>
      <xsl:copy-of select="tan:help-or-info($diagnostic-message, $fix, $fix-type, false())"/>
   </xsl:function>
   <xsl:function name="tan:info" as="element()">
      <xsl:param name="diagnostic-message" as="item()*"/>
      <xsl:param name="fix" as="item()*"/>
      <xsl:param name="fix-type" as="xs:string?"/>
      <xsl:copy-of select="tan:help-or-info($diagnostic-message, $fix, $fix-type, true())"/>
   </xsl:function>
   <xsl:function name="tan:help-or-info" as="element()">
      <!-- Input: a sequence of items to populate a message, a series of items to be used in a SQFix, and a boolean value indicating whether the output element should be named info (rather than help) -->
      <!-- Output: an element with the appropriate help or info message -->
      <xsl:param name="diagnostic-message" as="item()*"/>
      <xsl:param name="fix" as="item()*"/>
      <xsl:param name="fix-type" as="xs:string?"/>
      <xsl:param name="is-info" as="xs:boolean"/>
      <xsl:element name="{if ($is-info = true()) then 'info' else 'help'}">
         <xsl:for-each select="$diagnostic-message">
            <message>
               <xsl:value-of select="."/>
            </message>
         </xsl:for-each>
         <xsl:copy-of select="tan:fix($fix, $fix-type)"/>
      </xsl:element>
   </xsl:function>
   <xsl:function name="tan:help-requested" as="xs:boolean">
      <xsl:param name="node" as="node()?"/>
      <xsl:value-of
         select="
            if ((some $i in ($node, $node/@*)
               satisfies matches($i, $help-trigger-regex)) or exists($node/@help) or exists($node/tan:help)) then
               true()
            else
               false()"
      />
   </xsl:function>

   <xsl:function name="tan:fragment-to-text" as="xs:string?">
      <!-- Input: any document fragment -->
      <!-- Output: a string representation of the fragment -->
      <!-- This function is used to represent XML fragments in a plain text message, used particularly in validation reports -->
      <xsl:param name="fragment" as="item()*"/>
      <xsl:variable name="results" as="xs:string*">
         <xsl:apply-templates select="$fragment" mode="fragment-to-text"/>
      </xsl:variable>
      <xsl:value-of select="string-join($results, '')"/>
   </xsl:function>
   <xsl:template match="*" mode="fragment-to-text">
      <xsl:text>&lt;</xsl:text>
      <xsl:value-of select="name()"/>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:choose>
         <xsl:when test="exists(node())">
            <xsl:text>></xsl:text>
            <xsl:apply-templates select="node()" mode="#current"/>
            <xsl:text>&lt;/</xsl:text>
            <xsl:value-of select="name()"/>
            <xsl:text>></xsl:text>
         </xsl:when>
         <xsl:otherwise>
            <xsl:text> /></xsl:text>
         </xsl:otherwise>
      </xsl:choose>

   </xsl:template>
   <xsl:template match="@*" mode="fragment-to-text">
      <xsl:text> </xsl:text>
      <xsl:value-of select="name()"/>
      <xsl:text>='</xsl:text>
      <xsl:value-of select="."/>
      <xsl:text>'</xsl:text>
   </xsl:template>
   <xsl:template match="comment()" mode="fragment-to-text">
      <xsl:text>&lt;!--</xsl:text>
      <xsl:value-of select="."/>
      <xsl:text>--></xsl:text>
   </xsl:template>

   <xsl:function name="tan:idrefs" as="node()*">
      <!-- Input: a string; documents or document fragments -->
      <!-- Output: the elements that have an @xml:id value that matches the string, after it has been normalized and resolved for proxies -->
      <xsl:param name="idrefs" as="xs:string?"/>
      <xsl:param name="nodes" as="node()*"/>
      <xsl:variable name="idrefs-norm" select="tokenize(tan:normalize-text($idrefs), ' ')"/>
      <xsl:sequence select="tan:idrefs-loop($idrefs-norm, (), $nodes, ())"/>
   </xsl:function>
   <xsl:function name="tan:idrefs-loop" as="node()*">
      <!-- Loop function for tan:idrefs -->
      <xsl:param name="id-refs-to-check" as="xs:string*"/>
      <xsl:param name="results-so-far" as="node()*"/>
      <xsl:param name="nodes-to-check" as="node()*"/>
      <xsl:param name="alias-ids-already-checked" as="xs:string*"/>
      <xsl:choose>
         <xsl:when test="not(exists($id-refs-to-check))">
            <xsl:sequence select="$results-so-far"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:variable name="nodes-that-match"
               select="$nodes-to-check//*[@xml:id = $id-refs-to-check]"/>
            <xsl:variable name="proxies-that-match" select="$nodes-that-match/self::tan:alias"/>
            <xsl:variable name="ids-that-match-nothing"
               select="$id-refs-to-check[not(. = $nodes-that-match/@xml:id)]"/>
            <xsl:if test="exists($ids-that-match-nothing)">
               <xsl:copy-of select="tan:error('tan05', $ids-that-match-nothing)"/>
            </xsl:if>
            <xsl:choose>
               <xsl:when test="not(exists($proxies-that-match))">
                  <xsl:sequence select="$results-so-far, $nodes-that-match"/>
               </xsl:when>
               <xsl:when test="$proxies-that-match/@xml:id = $alias-ids-already-checked">
                  <xsl:sequence select="$results-so-far"/>
                  <xsl:copy-of
                     select="tan:error('tan14', $alias-ids-already-checked[. = $proxies-that-match/@xml:id])"
                  />
               </xsl:when>
               <xsl:otherwise>
                  <xsl:variable name="new-refs-to-check"
                     select="
                        for $i in $nodes-that-match/self::tan:alias
                        return
                           tokenize(tan:normalize-text($i/@idrefs), ' ')"/>
                  <xsl:sequence
                     select="tan:idrefs-loop($new-refs-to-check, ($results-so-far, $nodes-that-match[not(self::tan:alias)]), $nodes-to-check, ($alias-ids-already-checked, $nodes-that-match[self::tan:alias]/@xml:id))"
                  />
               </xsl:otherwise>
            </xsl:choose>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>


   <!-- STYLESHEETS TO GENERATE ERRORS -->

   <!-- default templates -->
   <xsl:template match="*"
      mode="core-errors referenced-doc-errors class-1-errors class-1-copy-errors">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="comment() | processing-instruction()"
      mode="core-errors core-attribute-errors referenced-doc-errors class-1-errors">
      <xsl:copy-of select="."/>
   </xsl:template>
   <xsl:template match="tan:error | tan:help | tan:warning | tan:fix | tan:fatal | tan:info"
      mode="core-attribute-errors core-errors">
      <xsl:copy-of select="."/>
   </xsl:template>

   <!-- core templates -->
   <xsl:template match="text()" mode="core-errors">
      <xsl:variable name="this-text" select="."/>
      <xsl:variable name="this-text-normalized" select="normalize-unicode(.)"/>
      <xsl:if test="$this-text != $this-text-normalized">
         <xsl:copy-of
            select="tan:error('tan04', concat('Should be: ', $this-text-normalized), $this-text-normalized, 'replace-text')"
         />
      </xsl:if>
      <xsl:if test="matches(., '^\p{M}')">
         <xsl:copy-of select="tan:error('cl111', (), replace(., '^\p{M}+', ''), 'replace-text')"/>
      </xsl:if>
      <xsl:if test="matches(., '\s\p{M}')">
         <xsl:copy-of
            select="tan:error('cl112', (), replace(., '\s+(\p{M})', '$1'), 'replace-text')"/>
      </xsl:if>
      <xsl:if test="matches(., $regex-characters-not-permitted)">
         <xsl:copy-of
            select="tan:error('cl113', (), replace(., $regex-characters-not-permitted, ''), 'replace-text')"
         />
      </xsl:if>
      <xsl:copy-of select="."/>
   </xsl:template>
   <xsl:template mode="core-errors"
      match="tan:TAN-T | tei:TEI | tan:TAN-A-div | tan:TAN-A-tok | tan:TAN-LM | tan:TAN-key | tan:TAN-c | tan:TAN-mor">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:copy-of select="tan:error('wrn04')"/>
         <xsl:apply-templates mode="core-errors"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:head" mode="core-errors">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="../tan:body/@in-progress = false() and not(exists(tan:master-location))">
            <xsl:variable name="this-fix">
               <master-location href="{$doc-uri}"/>
            </xsl:variable>
            <xsl:copy-of select="tan:error('tan02', '', $this-fix, 'add-master-location')"/>
         </xsl:if>
         <xsl:apply-templates mode="core-errors"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:inclusion | tan:key | tan:source | tan:see-also" mode="core-errors">
      <xsl:variable name="this-name" select="name(.)"/>
      <xsl:variable name="this-doc-id" select="root(.)/*/@id"/>
      <xsl:variable name="this-pos" select="count(preceding-sibling::*[name(.) = $this-name]) + 1"/>
      <xsl:variable name="this-IRI" select="tan:IRI"/>
      <xsl:variable name="this-class" select="tan:class-number(.)"/>
      <xsl:variable name="this-relationship-IRIs" select="tan:relationship/tan:IRI"/>
      <xsl:variable name="this-TAN-reserved-relationships"
         select="$TAN-keywords/tan:TAN-key/tan:body//tan:item[tan:IRI = $this-relationship-IRIs]"/>
      <xsl:variable name="target-1st-da-resolved" as="document-node()?">
         <xsl:choose>
            <xsl:when test="self::tan:inclusion and $this-doc-id = $doc-id">
               <xsl:copy-of select="$inclusions-resolved[position() = $this-pos]"/>
            </xsl:when>
            <xsl:when test="self::tan:key and $this-doc-id = $doc-id">
               <xsl:copy-of select="$keys-resolved[position() = $this-pos]"/>
            </xsl:when>
            <xsl:when test="self::tan:source and $this-doc-id = $doc-id">
               <xsl:copy-of select="$sources-resolved[position() = $this-pos]"/>
            </xsl:when>
            <xsl:when test="self::tan:see-also and $this-doc-id = $doc-id">
               <xsl:copy-of select="$see-alsos-resolved[position() = $this-pos]"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:copy-of select="tan:resolve-doc(tan:get-1st-doc(.))"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:variable name="target-class" select="tan:class-number($target-1st-da-resolved)"/>
      <xsl:variable name="target-is-faulty"
         select="
            deep-equal($target-1st-da-resolved, $empty-doc)
            or $target-1st-da-resolved/(tan:error, tan:warning, tan:fatal, tan:help)"/>
      <xsl:variable name="target-is-in-progress" as="xs:boolean?"
         select="
            if ($target-1st-da-resolved/*/(tan:body, tei:text/tei:body)/@in-progress = false())
            then
               false()
            else
               if (exists($target-1st-da-resolved/*/(tan:body, tei:text/tei:body))) then
                  true()
               else
                  ()"/>
      <xsl:variable name="target-new-versions"
         select="$target-1st-da-resolved/*/tan:head/tan:see-also[tan:has-relationship(., 'new version', ())]"/>
      <xsl:variable name="target-hist" select="tan:get-doc-hist($target-1st-da-resolved)"/>
      <xsl:variable name="target-id" select="$target-1st-da-resolved/*/@id"/>
      <!--<xsl:variable name="target-elements-with-ids"
         select="$target-1st-da//*[@xml:id][not(self::tan:inclusion)]"/>
      <xsl:variable name="idid" select="$all-ids"/>-->
      <!-- We change TEI to TAN-T, just so that TEI and TAN-T files can be treated as copies of each other -->
      <xsl:variable name="prov-root-name" select="replace(name($root/*), '^TEI$', 'TAN-T')"/>
      <xsl:variable name="target-accessed"
         select="max(tan:dateTime-to-decimal(tan:location/@when-accessed))"/>
      <xsl:variable name="target-updates"
         select="$target-hist/*[number(@when-sort) gt $target-accessed]"/>
      <xsl:variable name="duplicate-key-item-names" as="element()*">
         <xsl:for-each-group select="$keys-1st-da/tan:TAN-key/tan:body//tan:item"
            group-by="tokenize(tan:normalize-text((ancestor-or-self::*/@affects-element)[last()]), ' ')">
            <xsl:variable name="this-element-name" select="current-grouping-key()"/>
            <xsl:for-each-group select="current-group()" group-by="tan:name">
               <xsl:if
                  test="
                     count(current-group()) gt 1 and (some $i in current-group()
                        satisfies root($i)/*/@id = $target-1st-da-resolved/*/@id)">
                  <duplicate affects-element="{$this-element-name}" name="{current-grouping-key()}"
                  />
               </xsl:if>
            </xsl:for-each-group>
         </xsl:for-each-group>
      </xsl:variable>
      <xsl:variable name="duplicate-key-item-IRIs" as="element()*">
         <xsl:for-each-group select="$keys-1st-da/tan:TAN-key/tan:body//tan:item" group-by="tan:IRI">
            <xsl:if
               test="
                  count(current-group()) gt 1 and (some $i in current-group()
                     satisfies root($i)/*/@id = $target-1st-da-resolved/*/@id)">
               <duplicate
                  affects-element="{distinct-values(for $i in current-group() return tokenize(tan:normalize-text(($i/ancestor-or-self::*/@affects-element)[1]),' '))}"
                  iri="{current-grouping-key()}"/>
            </xsl:if>
         </xsl:for-each-group>
      </xsl:variable>

      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if
            test="
               $this-TAN-reserved-relationships//ancestor::tan:group/tan:name = 'TAN files'
               and $target-class = 0">
            <xsl:copy-of
               select="tan:error('see01', concat('root element name: ', name($target-1st-da-resolved/*)))"
            />
         </xsl:if>
         <xsl:if
            test="
               $this-TAN-reserved-relationships//ancestor::tan:group/tan:name = 'TAN-c'
               and not(name($target-1st-da-resolved/*) = 'TAN-c')">
            <xsl:copy-of
               select="tan:error('see02', concat('root element name: ', name($target-1st-da-resolved/*)))"
            />
         </xsl:if>
         <xsl:if
            test="
               $this-TAN-reserved-relationships//ancestor::tan:group/tan:name = 'copies'
               and not(replace(name($target-1st-da-resolved/*), '^TEI$', 'TAN-T') = $prov-root-name)">
            <xsl:copy-of
               select="tan:error('see03', concat('root element name: ', name($target-1st-da-resolved/*)))"
            />
         </xsl:if>
         <xsl:if
            test="
               $this-TAN-reserved-relationships/tan:name = 'different work version' and
               not($prov-root-name = 'TAN-T'
               and $head/tan:declarations/tan:work/tan:IRI = $target-1st-da-resolved/(tei:TEI, tan:TAN-T)/tan:head/tan:declarations/tan:work/tan:IRI)">
            <xsl:copy-of select="tan:error('see04')"/>
         </xsl:if>
         <xsl:copy-of select="$target-1st-da-resolved/tan:error"/>
         <xsl:if test="exists(tan:location) and not($target-id = tan:IRI) and $target-class gt 0">
            <xsl:copy-of
               select="tan:error('loc02', concat('ID of see-also file: ', $target-id), $target-id, 'replace-text')"
            />
         </xsl:if>
         <xsl:if
            test="($doc-id = $target-1st-da-resolved/*/@id) and not(self::tan:see-also and $this-TAN-reserved-relationships/tan:name = ('new version', 'old version'))">
            <xsl:copy-of select="tan:error('loc03')"/>
         </xsl:if>
         <xsl:if test="exists($target-updates)">
            <xsl:variable name="this-message">
               <xsl:text>Target updated </xsl:text>
               <xsl:value-of select="count($target-updates)"/>
               <xsl:text> times since last accessed (</xsl:text>
               <xsl:for-each select="$target-updates">
                  <xsl:value-of select="concat('&lt;', name(.), '> ')"/>
                  <xsl:for-each select="(@when-accessed, @ed-when, @when)">
                     <xsl:value-of select="concat('[', ., '] ')"/>
                  </xsl:for-each>
               </xsl:for-each>
               <xsl:text>)</xsl:text>
            </xsl:variable>
            <xsl:copy-of select="tan:info($this-message, (), ())"/>
            <xsl:for-each select="$target-updates[@flags]">
               <xsl:variable name="this-id" select="@when"/>
               <xsl:choose>
                  <xsl:when test="@flags = ('warn', 'warning')">
                     <warning xml:id="{$this-id}">
                        <rule>
                           <xsl:value-of select="."/>
                        </rule>
                     </warning>
                  </xsl:when>
                  <xsl:when test="@flags = 'error'">
                     <error xml:id="{$this-id}">
                        <rule>
                           <xsl:value-of select="."/>
                        </rule>
                     </error>
                  </xsl:when>
                  <xsl:when test="@flags = 'fatal'">
                     <fatal xml:id="{$this-id}">
                        <rule>
                           <xsl:value-of select="."/>
                        </rule>
                     </fatal>
                  </xsl:when>
                  <xsl:when test="@flags = 'info'">
                     <info xml:id="{$this-id}">
                        <message>
                           <xsl:value-of select="."/>
                        </message>
                     </info>
                  </xsl:when>
               </xsl:choose>
            </xsl:for-each>
         </xsl:if>
         <xsl:if test="$target-is-in-progress = true()">
            <xsl:copy-of select="tan:error('wrn03')"/>
         </xsl:if>
         <xsl:if test="exists($target-new-versions)">
            <xsl:copy-of select="tan:error('wrn05')"/>
         </xsl:if>
         <xsl:if test="self::tan:inclusion and $target-is-faulty = true()">
            <xsl:copy-of select="tan:error('inc04')"/>
         </xsl:if>
         <xsl:if test="self::tan:key">
            <xsl:if test="$target-is-faulty = true()">
               <xsl:copy-of select="tan:error('whi04')"/>
            </xsl:if>
            <xsl:if test="exists($duplicate-key-item-names)">
               <xsl:copy-of
                  select="
                     tan:error('whi02', string-join(for $i in $duplicate-key-item-names
                     return
                        concat($i/@affects-element, ' ', $i/@name), '; '))"
               />
            </xsl:if>
            <xsl:if test="exists($duplicate-key-item-IRIs)">
               <xsl:copy-of
                  select="
                     tan:error('tan11', string-join(for $i in $duplicate-key-item-IRIs
                     return
                        concat($i/@affects-element, ' ', $i/@iri), '; '))"
               />
            </xsl:if>
         </xsl:if>
         <xsl:if test="self::tan:source and $target-is-faulty = true() and $this-class = 2">
            <xsl:copy-of select="tan:error('cl201')"/>
         </xsl:if>
         <xsl:apply-templates mode="core-errors">
            <xsl:with-param name="target-id" select="$target-id"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:alias" mode="core-errors">
      <xsl:variable name="these-entities" select="tan:idrefs(@idrefs, root())"/>
      <xsl:variable name="these-entity-names"
         select="
            distinct-values(for $i in $these-entities[not(self::tan:error)]
            return
               name($i))"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="exists(@idrefs) and not(exists($these-entities))">
            <xsl:copy-of select="tan:error('tan05')"/>
         </xsl:if>
         <xsl:if test="count($these-entity-names) gt 1">
            <xsl:variable name="this-message"
               select="concat('mixes ', string-join($these-entity-names, ', '))"/>
            <xsl:copy-of select="tan:error('tan13', $this-message)"/>
         </xsl:if>
         <xsl:copy-of select="$these-entities[self::tan:error]"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:agent[1]" mode="core-errors">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="not(exists($primary-agent))">
            <xsl:copy-of
               select="tan:error('tan01', concat('Need an agent with an IRI that begins tag:', $doc-namespace))"
            />
         </xsl:if>
         <xsl:apply-templates mode="core-errors"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:IRI" mode="core-errors">
      <xsl:param name="target-id" as="xs:string?"/>
      <xsl:variable name="names-a-TAN-file" select="tan:must-refer-to-external-tan-file(.)"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test=". = $duplicate-iris and not(parent::tan:relationship)">
            <xsl:copy-of select="tan:error('tan09', .)"/>
         </xsl:if>
         <xsl:if test="exists($target-id) and not(. = $target-id)">
            <xsl:copy-of
               select="tan:error('tan10', concat('Target document @id = ', $target-id), $target-id, 'replace-text')"
            />
         </xsl:if>
         <xsl:apply-templates mode="core-errors"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tei:div" mode="core-errors">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="exists(tei:div) and exists(tei:*[not(self::tei:div)])">
            <xsl:copy-of select="tan:error('tei01')"/>
         </xsl:if>
         <xsl:if test="exists(@include) and exists(@*[not(name() = ('ed-who', 'ed-when'))])">
            <xsl:copy-of select="tan:error('tei02')"/>
         </xsl:if>
         <xsl:if test="not(exists(@n) and exists(@type)) and not(exists(@include))">
            <xsl:copy-of select="tan:error('tei03')"/>
         </xsl:if>
         <xsl:apply-templates mode="core-errors"/>
      </xsl:copy>
   </xsl:template>

   <!-- core pass, but dealing with attributes only -->
   <xsl:template match="*" mode="core-attribute-errors">
      <xsl:variable name="this-from" select="tan:dateTime-to-decimal(@from)"/>
      <xsl:variable name="this-to" select="tan:dateTime-to-decimal(@to)"/>
      <xsl:variable name="this-element" select="."/>
      <xsl:variable name="these-refs" as="element()*">
         <xsl:for-each
            select="@*[name(.) = $id-idrefs//tan:idrefs/@attribute][parent::tan:* or parent::tei:div]">
            <!-- we concern ourselves only with attributes that are meant to refer to other entities in the document -->
            <xsl:variable name="this-attribute-name" select="name(.)"/>
            <xsl:variable name="help-requested" select="tan:help-requested(.)"/>
            <xsl:variable name="should-refer-to-which-element"
               select="
                  for $i in $id-idrefs//tan:id[tan:idrefs/@attribute = $this-attribute-name]/@element
                  return
                     tokenize($i, ' ')"/>
            <xsl:variable name="these-vals-norm" select="tokenize(tan:normalize-text(.), ' ')"/>
            <xsl:variable name="these-distinct-values" select="distinct-values($these-vals-norm)"/>
            <xsl:variable name="all-possible-valid-entities"
               select="$head//*[name(.) = $should-refer-to-which-element]"/>

            <xsl:variable name="entities-pointed-to"
               select="
                  if (. = '*') then
                     $all-possible-valid-entities
                  else
                     $all-possible-valid-entities[@xml:id = $these-vals-norm]"/>
            <xsl:variable name="value-normalized"
               select="string-join($entities-pointed-to/@xml:id, ' ')"/>
            <xsl:variable name="invalid-refs"
               select="$these-vals-norm[not(. = $entities-pointed-to/@xml:id)]"/>


            <attribute name="{$this-attribute-name}" val="{$value-normalized}">
               <xsl:if test="not($value-normalized = .)">
                  <xsl:attribute name="orig-val" select="."/>
               </xsl:if>
               <xsl:if test="not(exists($entities-pointed-to)) or exists($invalid-refs)">
                  <xsl:variable name="this-message">
                     <xsl:value-of
                        select="concat('@', $this-attribute-name, ' must point to valid values of ')"/>
                     <xsl:value-of
                        select="
                           string-join(for $i in $should-refer-to-which-element
                           return
                              concat('&lt;', $i, '>'), ', ')"/>
                     <xsl:value-of
                        select="concat(': delete ', ., ' or change to: ', string-join($all-possible-valid-entities/@xml:id, ' '))"
                     />
                  </xsl:variable>
                  <xsl:variable name="new-element-fixes" as="element()*">
                     <xsl:for-each select="$invalid-refs">
                        <xsl:variable name="this-bad-ref" select="."/>
                        <xsl:for-each select="$should-refer-to-which-element">
                           <xsl:element name="{.}">
                              <xsl:attribute name="xml:id" select="$this-bad-ref"/>
                           </xsl:element>
                        </xsl:for-each>
                     </xsl:for-each>
                  </xsl:variable>
                  <xsl:copy-of
                     select="tan:error('tan05', $this-message, $new-element-fixes, 'copy-element-after-last-of-type')"
                  />
               </xsl:if>
               <xsl:if
                  test="$help-requested or not(exists($entities-pointed-to)) or exists($invalid-refs)">
                  <xsl:variable name="this-fix" as="element()*">
                     <xsl:for-each select="$all-possible-valid-entities">
                        <xsl:sort
                           select="
                              some $i in $these-vals-norm
                                 satisfies matches(@xml:id, $i)"
                           order="descending"/>
                        <element>
                           <xsl:attribute name="{$this-attribute-name}" select="@xml:id"/>
                        </element>
                     </xsl:for-each>
                  </xsl:variable>
                  <xsl:choose>
                     <xsl:when test="$help-requested">
                        <xsl:variable name="this-message"
                           select="concat('Try: ', string-join($this-fix/@*, '; '))"/>
                        <xsl:copy-of select="tan:help((), $this-fix, 'copy-attributes')"/>
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:message select="$this-fix"/>
                        <xsl:copy-of select="tan:fix($this-fix, 'copy-attributes')"/>
                     </xsl:otherwise>
                  </xsl:choose>

               </xsl:if>
               <xsl:if test="count($these-vals-norm) gt count($these-distinct-values)">
                  <xsl:copy-of
                     select="tan:error('tan06', string-join($these-vals-norm[index-of($these-vals-norm, .)[2]], ' '))"
                  />
               </xsl:if>
            </attribute>
         </xsl:for-each>
      </xsl:variable>
      <xsl:variable name="dates"
         select="$this-from, $this-to, tan:dateTime-to-decimal((self::tan:*/@when, @ed-when, @when-accessed))"/>
      <xsl:variable name="this-href-resolved"
         select="resolve-uri(@href, (root()/*/@base-uri, $doc-uri)[1])"/>
      <xsl:copy>
         <xsl:for-each select="@*">
            <xsl:variable name="this-attr-name" select="name()"/>
            <xsl:variable name="ref-check" select="$these-refs[@name = $this-attr-name]"/>
            <xsl:choose>
               <xsl:when test="exists($ref-check)">
                  <xsl:attribute name="{$this-attr-name}" select="$ref-check/@val"/>
                  <xsl:if test="exists($ref-check/@orig-val)">
                     <xsl:attribute name="{concat('orig-',$this-attr-name)}"
                        select="$ref-check/@orig-val"/>
                  </xsl:if>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:copy-of select="."/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each>
         <xsl:if test="@xml:id = $duplicate-ids">
            <xsl:copy-of select="tan:error('tan03', concat('ids used so far: ', string-join($all-ids, ', ')))"/>
         </xsl:if>
         <xsl:if test="$dates = 0">
            <xsl:copy-of select="tan:error('whe01')"/>
         </xsl:if>
         <xsl:if test="
               some $i in $dates
                  satisfies $i > $now">
            <xsl:copy-of
               select="tan:error('whe02', concat('Currently ', string(current-dateTime())))"/>
         </xsl:if>
         <xsl:if test="exists(@from) and exists(@to) and ($this-from gt $this-to)">
            <xsl:copy-of select="tan:error('whe03')"/>
         </xsl:if>
         <xsl:if
            test="(@regex, @matches-m, @matches-tok, @val)[matches(., '\\[^knrtpPsSiIcCdDwW\\|.?*+(){}#x2D#x5B#x5D#x5E\]\[\^\-]')]">
            <xsl:copy-of select="tan:error('tan07')"/>
         </xsl:if>
         <xsl:if test="exists(@href) and (doc-available($this-href-resolved) = false())">
            <xsl:copy-of select="tan:error('wrn01')"/>
         </xsl:if>
         <xsl:if test="exists(self::tan:master-location) and matches(@href, '!/')">
            <xsl:copy-of select="tan:error('tan15')"/>
         </xsl:if>
         <xsl:if test="exists(@href) and not((self::tan:location, self::tan:master-location))">
            <xsl:variable name="target-doc" select="doc($this-href-resolved)"/>
            <xsl:variable name="target-IRI" select="$target-doc/*/@id"/>
            <xsl:variable name="target-name" select="$target-doc/*/tan:head/tan:name"/>
            <xsl:variable name="target-desc" select="$target-doc/*/tan:head/tan:desc"/>
            <xsl:variable name="this-message">
               <xsl:text>Target file has the following IRI + name pattern: </xsl:text>
               <xsl:value-of select="$target-IRI"/>
               <xsl:value-of select="concat(' (', $target-name[1], ')')"/>
            </xsl:variable>
            <xsl:variable name="this-fix" as="element()">
               <xsl:copy>
                  <xsl:copy-of select="@* except (@href, @orig-href, @q)"/>
                  <IRI>
                     <xsl:value-of select="$target-IRI"/>
                  </IRI>
                  <xsl:copy-of select="$target-name"/>
                  <xsl:copy-of select="$target-desc"/>
                  <location when-accessed="{current-dateTime()}"
                     href="{tan:uri-relative-to(@href, $doc-uri)}"/>
               </xsl:copy>
            </xsl:variable>
            <xsl:copy-of select="tan:error('tan08', $this-message, $this-fix, 'replace-self')"/>
         </xsl:if>
         <xsl:copy-of select="$these-refs/*"/>
         <xsl:apply-templates mode="core-attribute-errors"/>
      </xsl:copy>
   </xsl:template>

   <!-- errors imprinted upon documents that are retrieved via <location @href> -->
   <xsl:template match="/*" mode="referenced-doc-errors">
      <xsl:param name="errors" as="element()*" tunnel="yes"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:copy-of select="$errors"/>
         <xsl:apply-templates mode="referenced-doc-errors"/>
      </xsl:copy>
   </xsl:template>

</xsl:stylesheet>
