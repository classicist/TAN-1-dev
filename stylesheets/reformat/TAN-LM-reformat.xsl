<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="tag:textalign.net,2015:ns" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs tan tei" version="2.0">
   <xsl:import href="../../functions/TAN-LM-functions.xsl"/>
   <xsl:import href="../../functions/TAN-class-2-global-variables.xsl"/>
   <xsl:output indent="yes"/>
   <!-- Stylesheet to transform a TAN-LM file. Offers the following features:
        1. Reset <group>s of <ana>s
        2. Convert <tok> references to and from @pos and @val
        3. Recombine <ana>s
        4. Re-sort
        5. Feedback
    -->
   <xsl:param name="make-backup" as="xs:boolean" select="true()"/>
   <!-- This parameter takes a sequence of TAN sequence constructors (e.g., '1 - last', '4, 5, 
        last-4 - last-1'). If the parameter is not present, or if it is the zero-length string, 
        then no changes will be made. Then for every value, the <ana>s picked by the constructor 
        will be grouped. If the first value is '0' then all groups will be reset (every <ana> will 
        be made a child of <body>). 
    -->
   <xsl:param name="p1-re-group-anas" as="xs:string*"/>
   <!-- If the value is 'pos' then all <tok> values will be converted to @pos; likewise for
    'val'; for any other value no such transformation occurs -->
   <xsl:param name="p2-convert-tok-refs-to-pos-or-val" as="xs:string?"/>
   <!--Recombinations. Allowed values stored in $allowed-combinations
        Any other value will make no changes to the current <ana> combinations -->
   <xsl:param name="p3-recombination" as="xs:string?"/>
   <xsl:variable name="allowed-combinations" as="element()+">
      <combo id="tok" regex-match="^(1|tok)$">Combine on tok only</combo>
      <combo id="tok-l" regex-match="^(2|tok\Wl)$">Combine on tok, then on l</combo>
      <combo id="tok-m" regex-match="^(3|tok\Wm)$">Combine on tok, then on m</combo>
      <combo id="lm" regex-match="^(4|lm|l|m)$">Combine on lm combinations</combo>
      <combo id="scatter" regex-match="^(5|ungroup|distribute|scatter)$">Uncombine (each ana has
         only one tok and l + m combo)</combo>
   </xsl:variable>
   <xsl:variable name="combination-id"
      select="
         for $i in $allowed-combinations
         return
            if (matches($p3-recombination, $i/@regex-match)) then
               $i/@id
            else
               ()"/>
   <xsl:variable name="second-recombination" as="xs:string?"
      select="
         if (matches($combination-id, '-[lm]$'))
         then
            replace($combination-id, '.+(.)$', '$1')
         else
            ()"/>
   <!-- Sorting. Identify the element or attribute name upon which sorting should take place. 
        If the parameter does not exist, or value is a zero-length string, then no sorting
    happens. If a valid value is appended by \Wd(esc(ending)?)? then values will be sorted in 
    descending fashion; anything else results in ascending sorts. -->
   <xsl:param name="p5-primary-sort" as="xs:string?"/>
   <xsl:variable name="nodes-that-sort-alphabetically"
      select="
         ('l', 'm', 'ed-when', 'ed-who',
         'lexicon', 'morphology', 'cert', 'val')"/>
   <xsl:variable name="nodes-that-sort-by-source-sequence" select="('tok', 'ref')"/>
   <xsl:variable name="nodes-that-allowing-sorting" as="xs:string*"
      select="$nodes-that-sort-alphabetically, $nodes-that-sort-by-source-sequence"/>
   <xsl:variable name="descending-sort-regex" select="'\Wd(esc(ending)?)?$'"/>
   <xsl:variable name="sort-order"
      select="
         if (matches($p5-primary-sort, $descending-sort-regex)) then
            'descending'
         else
            'ascending'"/>
   <xsl:variable name="name-of-node-on-which-to-sort"
      select="replace($p5-primary-sort, $descending-sort-regex, '')[. = $nodes-that-allowing-sorting]"/>
   <!-- Regroup option after everything has been reformatted -->
   <xsl:param name="p6-re-re-group-anas" as="xs:string*"/>
   <!-- Feedback and cleanup. -->
   <xsl:variable name="p7-include-feedback" as="xs:boolean" select="true()"/>

   <!-- ################################################################################# -->

   <!-- OUTPUT -->
   <xsl:template match="/">
      <!--<result>hi</result>-->
      <!--<xsl:copy-of select="/"/>-->
      <!--<xsl:copy-of select="$regrouped-doc"/>-->
      <!--<xsl:copy-of select="$revised-tok-doc"/>-->
      <!--<xsl:copy-of select="$unconsolidated-doc"/>-->
      <!--<xsl:copy-of select="$re-sorted-doc"/>-->
      <xsl:copy-of select="$final-results-with-feedback"/>
      <xsl:if test="$make-backup">
         <xsl:variable name="new-version-no" select="replace(string(current-dateTime()), '\D', '')"/>
         <xsl:variable name="new-uri"
            select="replace($doc-uri, '(.+)(\..+)$', concat('$1-', $new-version-no, '$2'))"/>
         <xsl:result-document href="{$new-uri}">
            <xsl:copy-of select="/"/>
         </xsl:result-document>
      </xsl:if>
   </xsl:template>

   <!-- Default template handling -->
   <xsl:template match="node()"
      mode="re-group re-re-group no-groups revise-tok consolidate-anas re-sort feedback">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>

   <!-- STEP ONE: REGROUPING -->
   <xsl:variable name="regrouped-doc" as="document-node()">
      <xsl:document>
         <xsl:apply-templates select="/" mode="re-group"/>
      </xsl:document>
   </xsl:variable>
   <xsl:template match="tan:body" mode="re-group">
      <xsl:choose>
         <xsl:when test="some $i in $p1-re-group-anas satisfies matches($i, '((last)|(last-\d+)|(\d+))(\s*-\s*((last)|(last-\d+)|(\d+)))?(\s*,?\s+((last)|(last-\d+)|(\d+))(\s+-\s+((last)|(last-\d+)|(\d+)))?)*|.*\?\?\?.*')">
            <xsl:copy-of select="tan:re-group-anas(., $p1-re-group-anas)"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of select="."/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   <xsl:template match="tan:group" mode="no-groups">
      <xsl:apply-templates mode="#current"/>
   </xsl:template>
   <xsl:function name="tan:re-group-anas" as="element()">
      <xsl:param name="body-to-re-group" as="element()"/>
      <xsl:param name="sequences-to-check" as="xs:string*"/>
      <xsl:variable name="this-sequence" select="$sequences-to-check[1]"/>
      <xsl:variable name="ana-max" select="count($body-to-re-group/tan:ana)"/>
      <xsl:variable name="this-sequence-resolved"
         select="tan:sequence-expand($this-sequence, $ana-max)"/>
      <xsl:choose>
         <xsl:when test="not(exists($this-sequence)) or $this-sequence = ''">
            <xsl:copy-of select="$body-to-re-group"/>
         </xsl:when>
         <!-- if there's nothing to re-group, then skip it all -->
         <xsl:when test="$this-sequence = '0'">
            <xsl:variable name="new-body" as="element()">
               <xsl:apply-templates select="$body-to-re-group" mode="no-groups"/>
            </xsl:variable>
            <xsl:copy-of select="tan:re-group-anas($new-body, $this-sequence[position() gt 1])"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:variable name="anas-to-group"
               select="
                  $body-to-re-group/tan:ana[position() = $this-sequence-resolved]"/>
            <xsl:variable name="first-ana-to-group" select="$anas-to-group[1]"/>
            <xsl:variable name="new-body" as="element()">
               <body>
                  <xsl:copy-of select="$body-to-re-group/@*"/>
                  <xsl:copy-of select="$first-ana-to-group/preceding-sibling::node()"/>
                  <group>
                     <xsl:copy-of select="$anas-to-group"/>
                  </group>
                  <xsl:copy-of
                     select="$first-ana-to-group/following-sibling::node() except $anas-to-group"/>
               </body>
            </xsl:variable>
            <xsl:copy-of select="tan:re-group-anas($new-body, $this-sequence[position() gt 1])"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

   <!-- STEP TWO: CONVERTING TO AND FROM @VAL AND @POS -->
   <xsl:variable name="revised-tok-doc" as="document-node()">
      <xsl:choose>
         <xsl:when test="$p2-convert-tok-refs-to-pos-or-val = ('pos', 'val')">
            <xsl:document>
               <xsl:apply-templates select="$regrouped-doc" mode="revise-tok"/>
            </xsl:document>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of select="$regrouped-doc"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:variable>
   <xsl:template match="tan:tok" mode="revise-tok">
      <xsl:param name="pos-or-val-override" as="xs:string?"/>
      <xsl:variable name="pos-or-val"
         select="($pos-or-val-override, $p2-convert-tok-refs-to-pos-or-val)[1]"/>
      <xsl:variable name="this-tok" select="."/>
      <xsl:variable name="this-ref-norm" select="tan:normalize-refs(@ref)"/>
      <xsl:variable name="this-val-norm" select="(@val, '.')[1]"/>
      <xsl:variable name="that-div"
         select="$srcs-tokenized/tan:TAN-T/tan:body//tan:div[@ref = $this-ref-norm]"/>
      <xsl:variable name="tok-ceiling" select="count($that-div/tan:tok)"/>
      <xsl:variable name="this-pos-norm"
         select="
            if (@pos) then
               tan:sequence-expand(@pos, $tok-ceiling)
            else
               1"/>
      <xsl:for-each select="$this-pos-norm">
         <xsl:variable name="pos" select="."/>
         <xsl:variable name="that-tok"
            select="($that-div/tan:tok[matches(., $this-val-norm)])[$pos]"/>
         <tok>
            <xsl:copy-of select="$this-tok/(@ref, @cert, @chars, @cont, @ed-when, @ed-who)"/>
            <xsl:choose>
               <xsl:when test="$pos-or-val = 'pos'">
                  <xsl:attribute name="pos" select="$that-tok/@n"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:variable name="tok-val" select="$that-tok/text()"/>
                  <xsl:variable name="nth-tok-val"
                     select="count($that-tok/preceding-sibling::tan:tok[. = $tok-val]) + 1"/>
                  <xsl:attribute name="val" select="$tok-val"/>
                  <xsl:if test="$nth-tok-val gt 1">
                     <xsl:attribute name="pos" select="$nth-tok-val"/>
                  </xsl:if>
               </xsl:otherwise>
            </xsl:choose>
            <xsl:copy-of select="$this-tok/comment()"/>
         </tok>
      </xsl:for-each>
   </xsl:template>

   <!-- STEP THREE: CONSOLIDATING <ANA>S -->
   <xsl:variable name="unconsolidated-doc" as="document-node()">
      <xsl:choose>
         <xsl:when test="exists($combination-id)">
            <xsl:copy-of select="tan:unconsolidate-tan-lm($revised-tok-doc, $srcs-tokenized)"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of select="$revised-tok-doc"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:variable>
   <xsl:variable name="consolidated-doc" as="document-node()">
      <xsl:choose>
         <xsl:when test="$combination-id = ('tok', 'tok-l', 'tok-m', 'lm')">
            <xsl:document>
               <xsl:apply-templates select="$unconsolidated-doc" mode="consolidate-anas"/>
            </xsl:document>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of select="$unconsolidated-doc"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:variable>
   <xsl:template match="tan:body | tan:group" mode="consolidate-anas">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates select="*[not(self::tan:ana)]" mode="#current"/>
         <xsl:for-each-group select="tan:ana"
            group-by="
               tan:ana-grouping-key(if (starts-with($combination-id, 'tok')) then
                  tan:tok[not(@cont)]
               else
                  tan:lm)">
            <xsl:variable name="this-frag" select="tan:rebuild-ana-fragment(current-grouping-key())"/>
            <xsl:variable name="ana-comments" as="element()">
               <ana-comments>
                  <xsl:copy-of select="current-group()/(comment(), tan:comment)"/>
               </ana-comments>
            </xsl:variable>
            <ana>
               <xsl:copy-of select="$this-frag/@*"/>
               <xsl:for-each select="$ana-comments/node()">
                  <xsl:variable name="this-comment" select="."/>
                  <xsl:if
                     test="
                        not(some $i in preceding-sibling::node()
                           satisfies deep-equal($i, $this-comment))">
                     <xsl:copy-of select="."/>
                  </xsl:if>
               </xsl:for-each>
               <xsl:choose>
                  <xsl:when test="starts-with($combination-id, 'tok')">
                     <xsl:copy-of select="$this-frag/tan:tok"/>
                     <xsl:choose>
                        <xsl:when test="exists($second-recombination)">
                           <xsl:for-each-group select="current-group()/tan:lm"
                              group-by="tan:ana-grouping-key(descendant::*[name() = $second-recombination])">
                              <xsl:variable name="lm-comments" as="element()">
                                 <lm-comments>
                                    <xsl:copy-of select="current-group()/(comment(), tan:comment)"/>
                                 </lm-comments>
                              </xsl:variable>
                              <xsl:variable name="this-second-frag"
                                 select="tan:rebuild-ana-fragment(current-grouping-key())"/>
                              <lm>
                                 <xsl:copy-of select="$this-second-frag/tan:lm/@*"/>
                                 <xsl:for-each select="lm-comments/node()">
                                    <xsl:variable name="this-comment" select="."/>
                                    <xsl:if
                                       test="
                                          not(some $i in preceding-sibling::node()
                                             satisfies deep-equal($i, $this-comment))">
                                       <xsl:copy-of select="."/>
                                    </xsl:if>
                                 </xsl:for-each>
                                 <xsl:copy-of select="$this-second-frag/tan:lm/tan:l"/>
                                 <xsl:for-each-group group-by="tan:ana-grouping-key(.)"
                                    select="current-group()/*[not(name() = $second-recombination)]">
                                    <xsl:copy-of select="current-group()[1]"/>
                                 </xsl:for-each-group>
                                 <xsl:copy-of select="$this-second-frag/tan:lm/tan:m"/>
                              </lm>
                           </xsl:for-each-group>
                        </xsl:when>
                        <xsl:otherwise>
                           <xsl:copy-of select="current-group()/tan:lm"/>
                        </xsl:otherwise>
                     </xsl:choose>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:copy-of select="current-group()/tan:tok"/>
                     <lm>
                        <xsl:copy-of select="$this-frag/tan:lm/@*"/>
                        <xsl:copy-of select="$this-frag/tan:lm/tan:l"/>
                        <xsl:copy-of select="$this-frag/tan:lm/tan:m"/>
                     </lm>
                  </xsl:otherwise>
               </xsl:choose>
            </ana>
         </xsl:for-each-group>
      </xsl:copy>
   </xsl:template>

   <!-- STEP FOUR: RE-SORT -->
   <xsl:variable name="re-sorted-doc" as="document-node()">
      <xsl:choose>
         <xsl:when test="exists($name-of-node-on-which-to-sort)">
            <xsl:document>
               <xsl:apply-templates select="$consolidated-doc" mode="re-sort"/>
            </xsl:document>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence select="$consolidated-doc"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:variable>
   <xsl:variable name="srcs-ref-sequence" select="$srcs-tokenized/tan:TAN-T/tan:body//@ref"
      as="xs:string*"/>
   <xsl:template match="tan:group | tan:body" mode="re-sort">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates select="*[not(self::tan:ana)]" mode="#current"/>
         <xsl:for-each select="tan:ana">
            <xsl:sort order="{$sort-order}">
               <xsl:choose>
                  <xsl:when test="$name-of-node-on-which-to-sort = $nodes-that-sort-alphabetically">
                     <xsl:variable name="pre-sort">
                        <xsl:for-each
                           select=".//node()[name() = $name-of-node-on-which-to-sort]/text()">
                           <xsl:sort order="{$sort-order}"/>
                           <xsl:value-of select="."/>
                        </xsl:for-each>
                     </xsl:variable>
                     <xsl:copy-of select="$pre-sort[1]"/>
                  </xsl:when>
                  <xsl:when
                     test="$name-of-node-on-which-to-sort = $nodes-that-sort-by-source-sequence">
                     <xsl:copy-of
                        select="
                           min(for $i in .//tan:tok/@ref
                           return
                              index-of($srcs-ref-sequence, $i))"
                     />
                  </xsl:when>
               </xsl:choose>
            </xsl:sort>
            <xsl:copy-of select="."/>
         </xsl:for-each>
      </xsl:copy>
   </xsl:template>

   <!-- STEP FIVE: RE-REGROUP -->
   <xsl:variable name="re-regrouped-doc" as="document-node()">
      <xsl:document>
         <xsl:apply-templates select="$re-sorted-doc" mode="re-re-group"/>
      </xsl:document>
   </xsl:variable>
   <xsl:template match="tan:body" mode="re-re-group">
      <xsl:copy-of select="tan:re-group-anas(., $p6-re-re-group-anas)"/>
   </xsl:template>

   <!-- STEP SIX: FEEDBACK, FINAL CLEAN-UP -->
   <xsl:variable name="final-results-with-feedback" as="document-node()">
      <xsl:choose>
         <xsl:when test="$p7-include-feedback = true()">
            <xsl:document>
               <xsl:apply-templates select="$re-regrouped-doc" mode="feedback"/>
            </xsl:document>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence select="$re-regrouped-doc"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:variable>
   <xsl:function name="tan:count-ana-l-m-combos" as="xs:integer*">
      <xsl:param name="tan-lm-doc" as="document-node()*"/>
      <xsl:for-each select="$tan-lm-doc">
         <xsl:copy-of
            select="
               sum(for $i in //tan:ana
               return
                  count($i/tan:tok[not(@cont)]) * sum(for $j in $i/tan:lm
                  return
                     (count($j/tan:l) * count($j/tan:m))))"
         />
      </xsl:for-each>
   </xsl:function>
   <xsl:function name="tan:get-ana-l-m-combos" as="xs:string*">
      <xsl:param name="tan-lm-doc" as="document-node()"/>
      <xsl:for-each select="$tan-lm-doc">
         <xsl:for-each select="//tan:ana">
            <xsl:variable name="toks-to-val" as="element()*">
               <xsl:apply-templates select="tan:tok[not(@cont)]" mode="revise-tok">
                  <xsl:with-param name="pos-or-val-override" select="'tok'"/>
               </xsl:apply-templates>
            </xsl:variable>
            <xsl:copy-of
               select="
                  for $i in $toks-to-val,
                     $j in tan:lm,
                     $k in $j/tan:l,
                     $l in $j/tan:m
                  return
                     string-join(($i/@val, $k, $l), ' ')"
            />
         </xsl:for-each>
      </xsl:for-each>
   </xsl:function>
   <xsl:variable name="orig-combos" select="tan:count-ana-l-m-combos(/)" as="xs:integer"/>
   <xsl:variable name="orig-keys" as="xs:string*" select="tan:get-ana-l-m-combos(/)"/>
   <xsl:variable name="orig-key-max-length"
      select="
         max(for $i in $orig-keys
         return
            string-length($i))"/>
   <xsl:variable name="new-combos" select="tan:count-ana-l-m-combos($re-sorted-doc)" as="xs:integer"/>
   <xsl:variable name="new-keys" as="xs:string*" select="tan:get-ana-l-m-combos($re-sorted-doc)"/>
   <xsl:variable name="feedback-combo-counts" xml:space="preserve"><comment who="stylesheet" when="{current-date()}">
ana + l + m combination counts: <xsl:value-of select="count($orig-keys)"/> in original, <xsl:value-of select="count($new-keys)"/> in reformatted version.
</comment></xsl:variable>
   <xsl:variable name="feedback-combos" as="element()" xml:space="preserve"><comment who="stylesheet" when="{current-date()}">
  Original<xsl:value-of select="
               for $i in (1 to $orig-key-max-length)
               return
                  ' '"/>Results
  <xsl:for-each select="1 to max((count($orig-keys), count($new-keys)))"><xsl:variable name="pos" select="position()"/>
     <xsl:value-of select="$orig-keys[$pos]"/><xsl:value-of select="
                  for $i in
                  (1 to ($orig-key-max-length - string-length($orig-keys[$pos])))
                  return
                     ' '"/><xsl:value-of select="$new-keys[$pos]"/></xsl:for-each>
   </comment></xsl:variable>
   <xsl:variable name="change-log-item" as="element()" xml:space="preserve"><change who="stylesheet" when="{current-dateTime()}">
         Reformatted version at <xsl:value-of select="$doc-uri"/>, using the following parameters: 
           Groups before reformatting: <xsl:value-of select="$p1-re-group-anas"/> 
           Convert to @pos/val: <xsl:value-of select="$p2-convert-tok-refs-to-pos-or-val"/> 
           Recombination: <xsl:value-of select="$combination-id"/> 
           Sorted by: <xsl:value-of select="$name-of-node-on-which-to-sort"/> (<xsl:value-of select="$sort-order"/>)
           Groups after reformatting: <xsl:value-of select="$p6-re-re-group-anas"/> 
         </change></xsl:variable>
   <xsl:template match="tan:head" mode="feedback">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:text>&#xA;</xsl:text>
         <!--<xsl:copy-of select="$feedback-combo-counts"/>-->
         <!--<xsl:copy-of select="$feedback-combos"/>-->
         <xsl:copy-of select="node()"/>
         <xsl:copy-of select="$change-log-item"/>
      </xsl:copy>
   </xsl:template>
</xsl:stylesheet>
