<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="tag:textalign.net,2015:ns" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math"
   xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="tan fn tei xs math xd"
   version="3.0">
   <xd:doc scope="stylesheet">
      <xd:desc>
         <xd:p><xd:b>Updated </xd:b>Oct. 1, 2015</xd:p>
         <xd:p>Set of functions for TAN-LM files. Used by Schematron validation, but suitable for
            other contexts.</xd:p>
      </xd:desc>
   </xd:doc>
   <xsl:include href="TAN-class-2-functions.xsl"/>

   <xsl:variable name="morphologies" select="$head/tan:declarations/tan:morphology"/>
   <xsl:variable name="morphologies-prepped" as="element()*">
      <xsl:for-each select="$morphologies">
         <xsl:variable name="first-la" select="tan:first-loc-available(.)"/>
         <xsl:copy>
            <xsl:copy-of select="@*"/>
            <location href="{resolve-uri($first-la, $doc-uri)}"/>
         </xsl:copy>
      </xsl:for-each>
   </xsl:variable>
   <!--<xsl:variable name="morphologies-1st-la"
        select="
            for $i in $morphologies
            return
                tan:first-loc-available($i)"/>-->
   <!--<xsl:variable name="mory-1st-da"
        select="
            for $i in $morphologies-1st-la
            return
                doc(resolve-uri($i, $doc-uri))"/>-->
   <xsl:variable name="mory-1st-da-resolved"
      select="
         for $i in $morphologies-prepped
         return
            tan:resolve-doc(doc($i/tan:location/@href), $i/@xml:id, false())"/>
   <xsl:variable name="features-prepped" as="element()*">
      <xsl:for-each select="$mory-1st-da-resolved/tan:TAN-mor/tan:head/tan:declarations/tan:feature">
         <xsl:variable name="this-id" select="@xml:id"/>
         <xsl:variable name="this-code"
            select="root(current())/tan:TAN-mor/tan:body//tan:option[@feature = $this-id]/@code"/>
         <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="src" select="root(current())/tan:TAN-mor/@src"/>
            <xsl:copy-of select="$this-code"/>
         </xsl:copy>
      </xsl:for-each>
   </xsl:variable>
   <xsl:variable name="features-grouped" select="tan:group-by-IRIs($features-prepped)"/>
   <!-- probably can delete the following - - detritus? -->
   <!--<xsl:variable name="mory-1st-da-features" as="element()*">
        <xsl:for-each select="$mory-1st-da-resolved">
            <morphology>
                <xsl:for-each select="/tan:TAN-mor/tan:head/tan:declarations/tan:feature">
                    <xsl:copy>
                        <xsl:copy-of select="@*"/>
                        <xsl:copy-of
                            select="/tan:TAN-mor/tan:body/tan:option[@feature = current()/@xml:id]"
                        />
                    </xsl:copy>
                </xsl:for-each>
            </morphology>
        </xsl:for-each>
    </xsl:variable>-->

   <xsl:function name="tan:all-morph-codes" as="xs:string*">
      <!-- Change any sequence of morphological codes into a sequence of synonymous morphological codes
            Input: node() picking a TAN-R-mor file, a sequence of strings, each item being the value of
            tan:option/@code or tan:feature/@xml:id
         Output: sequence of strings returning all equivalent lowercased values of each tan:option/@code or tan:feature/@xml:id 
         E.g., ('NN','comma','.') - > ('nn','comma',',','.','period')
      -->
      <xsl:param name="morph" as="node()?"/>
      <xsl:param name="codes" as="xs:string*"/>
      <xsl:variable name="codes-norm"
         select="
            for $i in $codes
            return
               lower-case($i)"/>
      <xsl:variable name="id-equiv"
         select="
            for $i in $morph//tan:body/tan:option[lower-case(@code) = $codes-norm]/@feature
            return
               lower-case($i)"/>
      <xsl:variable name="code-equiv"
         select="
            for $i in $morph//tan:body/tan:option[lower-case(@feature) = ($id-equiv,
            $codes-norm)]/@code
            return
               lower-case($i)"/>
      <xsl:copy-of
         select="
            distinct-values(($codes-norm,
            $id-equiv,
            $code-equiv))"
      />
   </xsl:function>

   <xsl:function name="tan:expand-m" as="element()*">
      <!-- Expands an <m>. 
        Input: (1) one or more <m>s, (2) true/false indicating whether features should be counted 
        Output: that <m>, and for every code, the corresponding <feature> is inserted -->
      <xsl:param name="m" as="element()*"/>
      <xsl:param name="add-counts" as="xs:boolean"/>
      <xsl:variable name="pass-1" as="element()*">
         <xsl:for-each select="$m">
            <xsl:variable name="this-morphology-id" select="(ancestor-or-self::*/@morphology)[1]"/>
            <xsl:variable name="this-mory"
               select="$mory-1st-da-resolved[tan:TAN-mor/@src = $this-morphology-id]"/>
            <xsl:variable name="this-mory-is-categorized"
               select="
                  if ($this-mory/tan:TAN-mor/tan:body/tan:category) then
                     true()
                  else
                     false()"/>
            <xsl:variable name="code-parsed" as="element()*">
               <xsl:analyze-string select="." regex="\S+">
                  <xsl:matching-substring>
                     <match>
                        <xsl:value-of select="."/>
                     </match>
                  </xsl:matching-substring>
               </xsl:analyze-string>
            </xsl:variable>
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:for-each select="$code-parsed">
                  <xsl:variable name="pos" select="position()"/>
                  <xsl:variable name="this-code" select="."/>
                  <xsl:variable name="this-feature-id"
                     select="
                        if ($this-mory-is-categorized = true()) then
                           $this-mory/tan:TAN-mor/tan:body/tan:category[$pos]/tan:option[(@feature, @code) = $this-code]/@feature
                        else
                           ($this-mory/tan:TAN-mor/tan:body/tan:option[(@feature, @code) = $this-code]/@feature, $this-code)"/>
                  <xsl:variable name="this-feature"
                     select="$this-mory/tan:TAN-mor/tan:head/tan:declarations/tan:feature[@xml:id = $this-feature-id]"/>
                  <xsl:copy-of select="$this-feature"/>
               </xsl:for-each>
            </xsl:copy>
         </xsl:for-each>
      </xsl:variable>
      <xsl:variable name="counts" as="element()*">
         <xsl:for-each select="distinct-values($pass-1/tan:feature/@xml:id)">
            <count xml:id="{.}" count="{count($pass-1/tan:feature[@xml:id = current()])}"/>
         </xsl:for-each>
      </xsl:variable>
      <xsl:choose>
         <xsl:when test="$add-counts = true()">
            <xsl:for-each select="$pass-1">
               <m n="{position()}">
                  <xsl:for-each select="tan:feature">
                     <xsl:copy>
                        <xsl:copy-of select="@*"/>
                        <xsl:copy-of select="$counts[@xml:id = current()/@xml:id]/@count"/>
                        <xsl:copy-of select="*"/>
                     </xsl:copy>
                  </xsl:for-each>
               </m>
            </xsl:for-each>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of select="$pass-1"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

   <xsl:function name="tan:get-matching-lm-combos" as="element()*">
      <!-- Input: one <l> and one <m>
            Output: all matching combinations. If an <lm> has only one <l> and <m> (and both match)
            then the entire <lm> is picked. If there's only one <l> and many <m>s then only the <m> is picked;
            and vice versa. If there are many <m>s and <l>s then nothing is picked, since any alterations
            to any <l> or <m> in that case would affect other <l> + <m> combos that have not been picked.
            This function is useful for global deletions of a particular lexeme + 
            morphological code pair.
        -->
      <xsl:param name="l-element" as="element()"/>
      <xsl:param name="m-element" as="element()"/>
      <xsl:variable name="matching-lms"
         select="$l-element/ancestor::tan:body//tan:ana/tan:lm[tan:l = $l-element and tan:m = $m-element]"/>
      <xsl:for-each select="$matching-lms">
         <xsl:choose>
            <xsl:when test="count(./tan:l) eq 1 and count(./tan:m) eq 1">
               <xsl:sequence select="."/>
            </xsl:when>
            <xsl:when test="count(./tan:l) gt 1 and count(./tan:m) eq 1">
               <xsl:sequence select="tan:l[. = $l-element]"/>
            </xsl:when>
            <xsl:when test="count(./tan:l) eq 1 and count(./tan:m) gt 1">
               <xsl:sequence select="tan:m[. = $m-element]"/>
            </xsl:when>
         </xsl:choose>
      </xsl:for-each>
   </xsl:function>
   <xsl:function name="tan:get-matching-ls-or-ms" as="element()*">
      <!-- Input: one <l> or one <m>
            Output: all matching combinations. If an <lm> has only one <l>/<m>
            then the entire <lm> is picked. Otherwise, it picks only the <l>/<m>
            that matches.
            This function is useful for global deletions of a particular lexeme or 
            morphological code-->
      <xsl:param name="l-or-m-element" as="element()"/>
      <xsl:variable name="this-name" select="name($l-or-m-element)"/>
      <xsl:variable name="complement-name"
         select="
            if ($this-name = 'l') then
               'm'
            else
               'l'"/>
      <xsl:variable name="these-matches"
         select="$l-or-m-element/ancestor::tan:body//tan:ana/tan:lm[*[name(.) = $this-name and . = $l-or-m-element]]"/>
      <xsl:for-each select="$these-matches">
         <xsl:choose>
            <xsl:when test="count(./*[name(.) = $this-name]) eq 1">
               <xsl:sequence select="."/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="*[name(.) = $this-name and . = $l-or-m-element]"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>
   </xsl:function>

   <xsl:function name="tan:feature-test-check" as="xs:boolean">
      <!--  Checks to see if a logical expression of morphological codes (+ synonyms) is found in a given value of <m>
            Input: two strings, the first a morphological code to be checked to see if it matches the second, a logical
            expression of features; a third parameter, a node(), defines the morphology rule to be used (to reconcile
            synonyms in codes)
            Output: true() if a match is found, false() otherwise
            E.g., 'nn 1 m', '(NN | m), 2' - > false()
            E.g., 'nn 1 m', '(NN | m), 1' - > true()
      -->
      <xsl:param name="code" as="xs:string"/>
      <xsl:param name="feature-expr" as="xs:string"/>
      <xsl:param name="morph" as="node()?"/>
      <xsl:variable name="this-expr-norm"
         select="normalize-space(replace($feature-expr, '([\(\),|])', ' $1 '))"/>
      <xsl:variable name="this-expr-seq" select="tokenize($this-expr-norm, ' ')"/>
      <xsl:variable name="this-expr-seq-norm"
         select="
            for $i in $this-expr-seq
            return
               if ($i = ('(',
               ')',
               '|'))
               then
                  $i
               else
                  if ($i = ',')
                  then
                     '.+'
                  else
                     concat(' ', string-join(tan:escape(tan:all-morph-codes($morph, $i)), ' | '), ' ')"/>
      <xsl:variable name="commas" select="count($this-expr-seq[. = ','])"/>
      <xsl:variable name="this-code-norm"
         select="
            string-join(for $i in (1 to $commas + 1)
            return
               concat(' ', replace($code, '\s+', ' , '), ' '), ',')"/>
      <xsl:value-of select="matches($this-code-norm, string-join($this-expr-seq-norm, ''), 'i')"/>
   </xsl:function>

   <!--<xsl:function name="tan:regex-prep" as="xs:string+">
        <!-\- Converts a non-regex search string into a regex one.
            Input: a string to be searched
         Output: that string with reserved regex characters escaped
         E.g., '[.w]' - > '\[\.w\]' 
         Based on http://www.w3.org/TR/xpath-functions/#regex-syntax without #x00 escapes-\->
        <xsl:param name="str" as="xs:string+"/>
        <xsl:copy-of
            select="
                for $i in $str
                return
                    replace($i, '([-\|.?*+(){}\[\]\^])', '\\$1')"
        />
    </xsl:function>-->

   <xsl:function name="tan:get-lm-ids" as="xs:string*">
      <!-- Input: any number of <ana>
            Output: one string per combination of <l> + <m>, calculated by joining (1) the <l> value,
            (2)the <m> code, and (3) attribute values of <lm>, <l>, and <m>
        -->
      <xsl:param name="ana-elements" as="element()+"/>
      <xsl:for-each select="$ana-elements">
         <xsl:copy-of
            select="
               for $i in tan:lm,
                  $j in if ($i/tan:l) then
                     $i/tan:l
                  else
                     $empty-doc,
                  $k in if ($i/tan:m) then
                     $i/tan:m
                  else
                     $empty-doc
               return
                  concat($j, '###', $k, '###', string-join(for $l in ($i, $j, $k)[(@cert, @morphology, @lexicon, @def-ref)],
                     $m in $l/(@cert, @morphology, @lexicon, @def-ref)
                  return
                     concat('%', name($l), '%', name($m), '%', $m), '###'
                  ))"
         />
      </xsl:for-each>
   </xsl:function>

   <!-- Transformative templates -->
   <xsl:function name="tan:expand-per-lm" as="document-node()*">
      <!-- Takes a TAN-LM and consolidates it, creating one <ana> per individual <l> + <m> pair,
        then putting in it any <tok> that shares that data -->
      <xsl:param name="tan-lm-resolved" as="document-node()*"/>
      <xsl:for-each select="$tan-lm-resolved">
         <xsl:copy>
            <xsl:apply-templates mode="expand-lm"/>
         </xsl:copy>
      </xsl:for-each>
   </xsl:function>

   <xsl:template match="node()" mode="expand-lm convert-code-to-features">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:body" mode="expand-lm">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:for-each-group select="tan:ana" group-by="tan:get-lm-ids(current())">
            <xsl:sort select="current-grouping-key()"/>
            <xsl:variable name="this-l-and-m" select="tokenize(current-grouping-key(), '###')"/>
            <ana>
               <xsl:copy-of select="current-group()/tan:tok"/>
               <lm>
                  <xsl:copy-of select="current-group()/tan:lm/@cert"/>
                  <l>
                     <xsl:copy-of select="current-group()/tan:lm/tan:l/(@cert, @lexicon)"/>
                     <xsl:value-of select="$this-l-and-m[1]"/>
                  </l>
                  <m>
                     <xsl:copy-of select="current-group()/tan:lm/tan:l/(@cert, @morphology)"/>
                     <xsl:value-of select="$this-l-and-m[2]"/>
                  </m>
               </lm>
            </ana>
         </xsl:for-each-group>
      </xsl:copy>
   </xsl:template>

   <xsl:function name="tan:convert-code-to-features" as="document-node()*">
      <!-- adds to every <m> a <feature @xml:id> for every part of the code -->
      <xsl:param name="tan-lm-resolved" as="document-node()*"/>
      <xsl:for-each select="$tan-lm-resolved">
         <xsl:copy>
            <xsl:apply-templates mode="convert-code-to-features"/>
         </xsl:copy>
      </xsl:for-each>
   </xsl:function>
   <xsl:template match="tan:m" mode="convert-code-to-features">
      <xsl:variable name="this-mory-id" select="(ancestor-or-self::*/@morphology)[1]"/>
      <xsl:variable name="this-mory"
         select="$mory-1st-da-resolved/tan:TAN-mor[@src = $this-mory-id]"/>
      <xsl:variable name="this-mory-categories" select="$this-mory/tan:body/tan:category"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:value-of select="."/>
         <xsl:choose>
            <xsl:when test="exists($this-mory-categories)">
               <xsl:for-each select="tokenize(., '\s+')">
                  <xsl:variable name="this-code" select="."/>
                  <xsl:variable name="pos" select="position()"/>
                  <xsl:variable name="this-feature"
                     select="$this-mory-categories[$pos]/tan:option[@code = $this-code]/@feature"/>
                  <feature>
                     <xsl:value-of select="$this-feature"/>
                  </feature>
               </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
               <xsl:for-each select="tokenize(., '\s+')">
                  <feature>
                     <xsl:value-of select="."/>
                  </feature>
               </xsl:for-each>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:copy>
   </xsl:template>

   <xsl:function name="tan:add-tok-val" as="document-node()*">
      <!-- take a fully expanded TAN-LM file ($self4) and to each <tok> add the value of 
        the token chosen, as @val, and replacing any pre-existing @val with @val-orig -->
      <xsl:param name="tan-lm-resolved" as="document-node()*"/>
      <xsl:param name="src-tokenized" as="document-node()*"/>
      <xsl:for-each select="$tan-lm-resolved">
         <xsl:variable name="pos" select="position()"/>
         <xsl:copy>
            <xsl:apply-templates mode="add-tok-val">
               <xsl:with-param name="src-tokenized" select="$src-tokenized[$pos]"/>
            </xsl:apply-templates>
         </xsl:copy>
      </xsl:for-each>
   </xsl:function>
   <xsl:template match="node()" mode="add-tok-val">
      <xsl:param name="src-tokenized" as="document-node()?"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="src-tokenized" select="$src-tokenized"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:tok" mode="add-tok-val">
      <xsl:param name="src-tokenized" as="document-node()?"/>
      <xsl:variable name="this-ref" select="@ref"/>
      <xsl:variable name="this-n" select="@n"/>
      <xsl:variable name="this-match"
         select="$src-tokenized/tan:TAN-T/tan:body//tan:div[@ref = $this-ref]/tan:tok[@n = $this-n]"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="@val">
            <xsl:attribute name="val-orig" select="@val"/>
         </xsl:if>
         <xsl:attribute name="val" select="$this-match"/>
      </xsl:copy>
   </xsl:template>

   <xsl:function name="tan:rebuild-ana-fragment" as="element()*">
      <!-- Takes any set of strings that are the result of tan:[tok/l/m]-grouping-key()
            and for each one returns a rebuilt fragment of the original <ana> upon which 
            it is based. Useful for reconstructing fragments of documents after <xsl:for-each-group/>
            operations.
        -->
      <xsl:param name="tok-l-or-m-grouping-key" as="xs:string*"/>
      <xsl:for-each select="$tok-l-or-m-grouping-key">
         <xsl:variable name="these-nodes-to-build" as="element()*">
            <rebuild>
               <xsl:for-each select="tokenize(., $sep-2)[string-length(.) gt 0]">
                  <xsl:variable name="data" select="tokenize(., $sep-1)"/>
                  <xsl:element name="{$data[1]}">
                     <xsl:choose>
                        <xsl:when test="$data[2] = 'text()'">
                           <xsl:value-of select="$data[3]"/>
                        </xsl:when>
                        <xsl:when test="$data[2] = 'comment()'">
                           <xsl:comment select="$data[3]"/>
                        </xsl:when>
                        <xsl:otherwise>
                           <xsl:attribute name="{$data[2]}" select="$data[3]"/>
                        </xsl:otherwise>
                     </xsl:choose>
                  </xsl:element>
               </xsl:for-each>
            </rebuild>
         </xsl:variable>
         <ana>
            <xsl:copy-of select="$these-nodes-to-build/tan:ana/@*"/>
            <xsl:copy-of select="$these-nodes-to-build/tan:ana/comment()"/>
            <xsl:if test="exists($these-nodes-to-build/tan:preceding-tok-with-cont)">
               <tok cont="1">
                  <xsl:copy-of select="$these-nodes-to-build/tan:tok/@*"/>
               </tok>
            </xsl:if>
            <xsl:if test="exists($these-nodes-to-build/tan:tok)">
               <tok>
                  <xsl:copy-of select="$these-nodes-to-build/tan:tok/@*"/>
                  <xsl:copy-of select="$these-nodes-to-build/tan:tok/comment()"/>
               </tok>
            </xsl:if>
            <xsl:if test="exists($these-nodes-to-build/(tan:l, tan:m))">
               <lm>
                  <xsl:copy-of select="$these-nodes-to-build/tan:lm/@*"/>
                  <xsl:copy-of select="$these-nodes-to-build/tan:lm/comment()"/>
                  <xsl:if test="exists($these-nodes-to-build/tan:l)">
                     <l>
                        <xsl:copy-of select="$these-nodes-to-build/tan:l/@*"/>
                        <xsl:copy-of select="$these-nodes-to-build/tan:l/comment()"/>
                        <xsl:value-of select="$these-nodes-to-build/tan:l/text()"/>
                     </l>
                  </xsl:if>
                  <xsl:if test="exists($these-nodes-to-build/tan:m)">
                     <m>
                        <xsl:copy-of select="$these-nodes-to-build/tan:m/@*"/>
                        <xsl:copy-of select="$these-nodes-to-build/tan:m/comment()"/>
                        <xsl:value-of select="$these-nodes-to-build/tan:m/text()"/>
                     </m>
                  </xsl:if>
               </lm>
            </xsl:if>
         </ana>
      </xsl:for-each>
   </xsl:function>
   <!--<xsl:function name="tan:tok-grouping-key" as="xs:string*">
        <!-\- Input: zero or more <tok>s
        Output: an equal number of strings that concatenate the properties of that <tok>
        Especially made to be used in the @group-by value of <xsl:for-each-group /> statements.
        See also tan:rebuild-ana-fragment(), which can convert the value of tan:tok-properties() to
        an element fragment identical to the original.
        -\->
        <xsl:param name="tok-element" as="element()*"/>
        <xsl:for-each select="$tok-element">
            <xsl:variable name="this-tok" select="."/>
            <xsl:variable name="constructor" as="xs:string*">
                <xsl:for-each select="$tok-grouping-key-key/*">
                    <xsl:variable name="that-key" select="."/>
                    <xsl:variable name="that-key-node-name" select="$that-key/@*"/>
                    <xsl:choose>
                        <xsl:when test="name($that-key) = 'tok'">
                            <xsl:variable name="this-key-node-value"
                                select="$this-tok/@*[name() = $that-key-node-name]"/>
                            <xsl:value-of
                                select="
                                    if (exists($this-key-node-value)) then
                                        concat(name($that-key), $sep-1, $that-key-node-name, $sep-1, $this-key-node-value)
                                    else
                                        ()"
                            />
                        </xsl:when>
                        <xsl:when test="name($that-key) = 'preceding-tok-with-cont'">
                            <xsl:variable name="this-key-node-value"
                                select="$this-tok/preceding-sibling::tan:tok[1][@cont]/@*[name() = $that-key-node-name]"/>
                            <xsl:value-of
                                select="
                                    if (exists($this-key-node-value)) then
                                        concat(name($that-key), $sep-1, $that-key-node-name, $sep-1, $this-key-node-value)
                                    else
                                        ()"
                            />
                        </xsl:when>
                        <xsl:when test="name($that-key) = 'ana'">
                            <xsl:variable name="this-key-node-value"
                                select="$this-tok/parent::tan:ana/@*[name() = $that-key-node-name]"/>
                            <xsl:value-of
                                select="
                                    if (exists($this-key-node-value)) then
                                        concat(name($that-key), $sep-1, $that-key-node-name, $sep-1, $this-key-node-value)
                                    else
                                        ()"
                            />
                        </xsl:when>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:variable>
            <xsl:value-of select="string-join($constructor, $sep-2)"/>
        </xsl:for-each>
    </xsl:function>-->
   <xsl:function name="tan:ana-grouping-key" as="xs:string*">
      <!-- Input: zero or more <tok>, <lm>, <l>, or <m>s
        Output: an equal number of strings that concatenate the properties of that element
        Especially made to be used in the @group-by value of <xsl:for-each-group /> statements.
        See also tan:rebuild-ana-fragment(), which can reconstruct the <ana> fragment.
        -->
      <xsl:param name="tok-lm-l-or-m-element" as="element()*"/>
      <xsl:for-each select="$tok-lm-l-or-m-element">
         <xsl:variable name="this-element" select="."/>
         <xsl:variable name="this-element-name" select="name($this-element)"/>
         <xsl:variable name="this-key"
            select="
               if ($this-element-name = 'tok') then
                  $tok-grouping-key-key
               else
                  if ($this-element-name = 'l') then
                     $l-grouping-key-key
                  else
                     if ($this-element-name = 'm') then
                        $m-grouping-key-key
                     else
                        ()"/>
         <xsl:variable name="constructor" as="xs:string*">
            <xsl:for-each select="$this-key/*">
               <xsl:variable name="that-key-item" select="."/>
               <xsl:variable name="context" select="name($that-key-item)"/>
               <xsl:variable name="that-key-node-name" select="$that-key-item/@*"/>
               <xsl:choose>
                  <xsl:when test="$context = ('l', 'm', 'tok')">
                     <xsl:variable name="this-key-node-value"
                        select="
                           if ($that-key-node-name = 'text()')
                           then
                              $this-element/text()
                           else
                              if ($that-key-node-name = 'comment()')
                              then
                                 $this-element/comment()
                              else
                                 $this-element/@*[name() = $that-key-node-name]"/>
                     <xsl:value-of
                        select="
                           if (exists($this-key-node-value)) then
                              concat(name($that-key-item), $sep-1, $that-key-node-name, $sep-1, $this-key-node-value)
                           else
                              ()"
                     />
                  </xsl:when>
                  <xsl:when test="$context = 'preceding-tok-with-cont'">
                     <xsl:variable name="this-key-node-value"
                        select="$this-element/preceding-sibling::tan:tok[1][@cont]/@*[name() = $that-key-node-name]"/>
                     <xsl:value-of
                        select="
                           if (exists($this-key-node-value)) then
                              concat(name($that-key-item), $sep-1, $that-key-node-name, $sep-1, $this-key-node-value)
                           else
                              ()"
                     />
                  </xsl:when>
                  <xsl:when test="$context = 'lm'">
                     <xsl:variable name="this-key-node-value"
                        select="$this-element/parent::tan:lm/@*[name() = $that-key-node-name]"/>
                     <xsl:value-of
                        select="
                           if (exists($this-key-node-value)) then
                              concat(name($that-key-item), $sep-1, $that-key-node-name, $sep-1, $this-key-node-value)
                           else
                              ()"
                     />
                  </xsl:when>
                  <xsl:when test="$context = 'ana'">
                     <xsl:variable name="this-key-node-value"
                        select="$this-element/ancestor::tan:ana/@*[name() = $that-key-node-name]"/>
                     <xsl:value-of
                        select="
                           if (exists($this-key-node-value)) then
                              concat(name($that-key-item), $sep-1, $that-key-node-name, $sep-1, $this-key-node-value)
                           else
                              ()"
                     />
                  </xsl:when>
               </xsl:choose>
            </xsl:for-each>
         </xsl:variable>
         <xsl:choose>
            <xsl:when test="not($this-element-name = 'lm')">
               <xsl:value-of select="string-join($constructor, $sep-2)"/>
            </xsl:when>
            <xsl:otherwise>
               <!-- If it's an <lm> then you need to iterate over every <l> + <m> combo -->
               <xsl:variable name="lm-constructor" as="xs:string*">
                  <xsl:copy-of
                     select="
                        for $i in $this-element/tan:l,
                           $j in $this-element/tan:m
                        return
                           string-join(tan:ana-grouping-key(($i, $j)), $sep-2)"
                  />
               </xsl:variable>
               <xsl:copy-of select="$lm-constructor"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>
   </xsl:function>
   <xsl:variable name="sep-1" select="'%'"/>
   <xsl:variable name="sep-2" select="'#'"/>
   <xsl:variable name="tok-grouping-key-key" as="element()">
      <tok-grouping-key-key>
         <tok attribute="ref"/>
         <tok attribute="key"/>
         <tok attribute="val"/>
         <tok attribute="pos"/>
         <tok attribute="chars"/>
         <tok attribute="cert"/>
         <tok attribute="ed-who"/>
         <tok attribute="ed-when"/>
         <tok attribute="comment()"/>
         <preceding-tok-with-cont attribute="ref"/>
         <preceding-tok-with-cont attribute="val"/>
         <preceding-tok-with-cont attribute="pos"/>
         <preceding-tok-with-cont attribute="chars"/>
         <preceding-tok-with-cont attribute="cert"/>
         <preceding-tok-with-cont attribute="ed-who"/>
         <preceding-tok-with-cont attribute="ed-when"/>
         <ana attribute="xml:id"/>
         <ana attribute="cert"/>
         <ana attribute="ed-who"/>
         <ana attribute="ed-when"/>
      </tok-grouping-key-key>
   </xsl:variable>
   <xsl:variable name="l-grouping-key-key" as="element()">
      <l-grouping-key-key>
         <l attribute="text()"/>
         <l attribute="lexicon"/>
         <l attribute="def-ref"/>
         <l attribute="cert"/>
         <l attribute="ed-who"/>
         <l attribute="ed-when"/>
         <l attribute="comment()"/>
         <lm attribute="cert"/>
         <lm attribute="ed-who"/>
         <lm attribute="ed-when"/>
         <ana attribute="xml:id"/>
         <ana attribute="cert"/>
         <ana attribute="ed-who"/>
         <ana attribute="ed-when"/>
      </l-grouping-key-key>
   </xsl:variable>
   <xsl:variable name="m-grouping-key-key" as="element()">
      <m-grouping-key-key>
         <m attribute="text()"/>
         <m attribute="morphology"/>
         <m attribute="cert"/>
         <m attribute="ed-who"/>
         <m attribute="ed-when"/>
         <m attribute="comment()"/>
         <lm attribute="cert"/>
         <lm attribute="ed-who"/>
         <lm attribute="ed-when"/>
         <ana attribute="xml:id"/>
         <ana attribute="cert"/>
         <ana attribute="ed-who"/>
         <ana attribute="ed-when"/>
      </m-grouping-key-key>
   </xsl:variable>
</xsl:stylesheet>
