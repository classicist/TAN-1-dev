<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
   <title>Schematron tests for TAN-A-div files.</title>
   <ns prefix="tan" uri="tag:textalign.net,2015:ns"/>
   <ns prefix="tei" uri="http://www.tei-c.org/ns/1.0"/>
   <ns prefix="xs" uri="http://www.w3.org/2001/XMLSchema"/>
   <ns prefix="xsl" uri="http://www.w3.org/1999/XSL/Transform"/>

   <include href="TAN-core.sch"/>
   <include href="TAN-class-2.sch"/>
   <pattern>
      <rule context="tan:rename">
         <let name="this-src-list" value="tan:src-ids-to-nos(../@src)"/>
         <let name="this-old" value="@old"/>
         <let name="this-new" value="@new"/>
         <let name="sibling-olds" value="(preceding-sibling::tan:rename, following-sibling::tan:rename)/@old"/>
         <let name="sibling-news" value="(preceding-sibling::tan:rename, following-sibling::tan:rename)/@new"/>
         <report test="$this-old = $sibling-olds">Old values may not be duplicated</report>
         <report test="$this-new = $sibling-news">New values may not be duplicated</report>
         <report test="for $i in $this-src-list return $src-1st-da-all-div-types/tan:source[$i]/tan:div-type[@xml:id=$this-new]">
            You may not change a name into one that is already in use by the source as a div-type id.
         </report>
      </rule>
      <rule context="tan:equate-works">
         <let name="this-src-list" value="tan:src-ids-to-nos(@src)"/>
         <let name="this-work-iris" value="for $i in $this-src-list return $src-1st-da-heads[$i]/tan:declarations/tan:work/tan:IRI"/>
         <let name="repeated-works" value="$this-work-iris[index-of($this-work-iris,.)[2]]"/>
         <report test="exists($repeated-works)" role="warning">Works that already have at least one shared IRI need not be equated.
            <value-of select="$repeated-works"/></report>
         <report test="matches(@src,'\?')" role="info"><!-- If there is a question mark in @src, validation will return a list of works currently clustered -->Help: current work groups: <value-of select="for $i in
            distinct-values($equate-works) return concat('(',string-join(for $j in index-of($equate-works,$i) return $src-ids[$j],' '),')')"/></report>
      </rule>
      <rule context="tan:equate-div-types">
         <let name="this-src-list"
            value="for $i in tan:div-type-ref,
                  $j in tan:src-ids-to-nos($i/@src),
                  $k in tokenize($i/@div-type-ref, '\s+')
               return
                  $j"/>
         <let name="this-div-type-list"
            value="for $i in tan:div-type-ref,
                  $j in tan:src-ids-to-nos($i/@src),
                  $k in tokenize($i/@div-type-ref, '\s+')
               return
                  $k"/>
         <let name="this-src-div-type-equivs"
            value="for $i in (2 to count($this-src-list)),
                  $j in (1 to ($i - 1))
               return
                  if ($src-1st-da-heads[$this-src-list[$i]]/tan:declarations/tan:div-type[@xml:id = $this-div-type-list[$i]]/tan:IRI/text() = $src-1st-da-heads[$this-src-list[$j]]/tan:declarations/tan:div-type[@xml:id = $this-div-type-list[$j]]/tan:IRI/text())
                  then
                     concat($src-ids[$this-src-list[$i]], ' : ', $this-div-type-list[$i], ' = ', $src-ids[$this-src-list[$j]], ' : ', $this-div-type-list[$j])
                  else
                     ()"/>
         <report test="exists($this-src-div-type-equivs)" role="warning">Div types that already have at least one shared IRI need not be equated.
               <value-of select="string-join($this-src-div-type-equivs, ', ')"/></report>
      </rule>
      <rule context="tan:div-type-ref">
         <let name="this-src-list"
            value="for $i in tan:src-ids-to-nos(@src),
                  $j in tokenize(@div-type-ref, '\s+')
               return
                  $i"/>
         <let name="this-div-type-list"
            value="for $i in $this-src-list,
                  $j in tokenize(@div-type-ref, '\s+')
               return
                  $j"/>
         <let name="this-is-duplicate"
            value="for $i in (1 to count($this-src-list))
               return
                  if ((preceding-sibling::tan:div-type-ref,
                  following-sibling::tan:div-type-ref,
                  ../preceding-sibling::tan:equate-div-types/tan:div-type-ref,
                  ../following-sibling::tan:equate-div-types/tan:div-type-ref)[tokenize(@src, '\s+') = $src-ids[$this-src-list[$i]]][tokenize(@div-type-ref, '\s+') = $this-div-type-list[$i]])
                  then
                     concat($src-ids[$this-src-list[$i]], ' : ', $this-div-type-list[$i])
                  else
                     ()"/>
         <report test="exists($this-is-duplicate)">Div-type-refs may not be duplicated (<value-of
               select="string-join($this-is-duplicate, ', ')"/>).</report>
      </rule>
      <rule context="tan:split-leaf-div-at">
         <let name="all-splits" value="for $i in tan:tok return tan:pick-tokenized-prepped-class-1-data($i)"/>
         <assert test="//tan:tokenization">If a leaf div is to be split, there must be at least one
            tokenization declared.</assert>
      </rule>
      <rule context="tan:tok">
         <let name="this-pos" value="count(preceding-sibling::tan:tok) + 1"/>
         <let name="help-requested" value="tan:help-requested(.)"/>
         <let name="these-splits" value="if ($help-requested) then () else tan:pick-tokenized-prepped-class-1-data(.)"/>
         <let name="duplicate-splits" value="for $i in $these-splits//tan:tok return
            if ($leaf-div-splits-raw[position() ne $this-pos]/tan:source[@id = $i/../../@id]/tan:div[@ref = $i/../@ref]/tan:tok[@n = $i/@n]) 
            then concat($i/../../@id,': ',$i/../@ref,' tok ',$i/@n) else ()"/>
         <report test="exists($duplicate-splits) and not($help-requested)">May not be used to split a leaf div more than once in the 
            same place (<value-of select="string-join($duplicate-splits,' ')"/>).</report>
         <assert test="tan:src-ids-to-nos(@src) = $tokenized-sources">Requires a tokenization
            declaration.</assert>
         <report test="$these-splits//@error" tan:does-not-apply-to="tok">Tokenization error: <value-of select="for $i in $these-splits//@error return
            $tokenization-errors[$i]"/></report>
      </rule>
      <rule context="tan:realign">
         <let name="these-srcs" value="tan:src-ids-to-nos(.//@src)"/>
         <let name="these-works"
            value="for $i in $these-srcs
               return
                  $equate-works[$i]"
         />
         <let name="this-normalized" value="tan:normalize-realign(.)"/>
         <report test="count(distinct-values($these-works)) ne 1">realign sources must all share the
            same work (<value-of select="count(distinct-values($these-works))"/> works currently
            referred to)</report>
         <report test="$this-normalized/@error">Distribution enforced: each source must have the same
            number of single references (unmatched: <value-of select="$this-normalized[@error]/tan:div-ref/@*"/>)
         </report>
      </rule>
      <rule context="tan:align">
         <let name="this-src-list" value="tan:src-ids-to-nos(tan:div-ref/@src)"/>
         <let name="this-work-list" value="for $i in $this-src-list return $equate-works[$i]"/>
         <let name="this-align-normalized" value="tan:normalize-align(.)"/>
         <report test="@distribute and count(tan:div-ref) eq 1">@distribute
            has no effect on an align that has only one &lt;div-ref>.</report>
         <report test="$this-align-normalized/@error">@distribute requires one-to-one correlation
            between each atomic ref in each work / source (uncorrelated: <value-of
               select="$this-align-normalized[@error]/tan:div-ref/(@ref,
                  @seg)"
            />)</report>
      </rule>
      <rule context="tan:div-ref|tan:anchor-div-ref">
         <let name="this" value="."/>
         <let name="is-being-realigned" value="if (name(..) = 'realign') then true() else false()"/>
         <let name="is-anchor" value="if (name(.) = 'anchor-div-ref') then true() else false()"/>
         <let name="this-src-list" value="tan:src-ids-to-nos(@src)"/>
         <let name="these-srcs-tokenized" value="$this-src-list[. = $tokenized-sources]"/>
         <let name="this-refs-norm"
            value="for $i in $this-src-list
               return
                  if ($i = $src-impl-div-types) then
                     tan:normalize-impl-refs(@ref, $i)
                  else
                     tan:normalize-refs(@ref)"/>
         <let name="these-div-types"
            value="distinct-values(for $i in $this-refs-norm, $j in tokenize($i, ' [-,] '),
                  $k in tokenize($j, $separator-hierarchy-regex)
               return
                  tokenize($k, $separator-type-and-n-regex)[1])"
         />
         <let name="valid-div-types"
            value="distinct-values(for $i in $this-src-list
               return
                  $src-1st-da-all-div-types/tan:source[$i]//@xml:id)"
         />
         <let name="qty-of-srcs-with-implicit-div-types"
            value="count($this-src-list[. = $src-impl-div-types])"/>
         <let name="src-data-for-this-div-ref" value="tan:pick-prepped-class-1-data($this-src-list, $this-refs-norm)"/>
         <let name="src-segmented-data-for-this-div-ref"
            value="tan:segment-tokenized-prepped-class-1-data(tan:tokenize-prepped-class-1-data($src-data-for-this-div-ref))"/>
         <let name="duplicate-sibling"
            value="for $i in (preceding-sibling::node(),
               following-sibling::node())
               return
                  if (deep-equal($this, $i)) then
                     true()
                  else
                     ()"/>
         <let name="this-parent-normalized"
            value="if ($is-being-realigned) then
                  tan:normalize-realign(..)
               else
                  tan:normalize-align(..)"
         />
         <let name="anchor-is-realigned"
            value="for $i in $this-parent-normalized/tan:anchor-div-ref
               return
                  if ($realigns-normalized/tan:div-ref[@src = $i/@src][@ref = $i/@ref][(@seg = $i/@seg) or not($i/@seg)]) then
                     true()
                  else
                     false()"
         />
         <let name="div-ref-is-anchored" value="for $i in tan:expand-div-ref(.,true()) return
            if ($realigns-normalized/tan:anchor-div-ref[@src = $i/@src][@ref = $i/@ref][(@seg = $i/@seg) or not(@seg)]) then true() else false()"/>
         <let name="ref-has-errors" value="$src-data-for-this-div-ref/tan:div/@error"/>
         <let name="div-type-mismatches" value="$these-div-types[not(. = $valid-div-types)]"/>
         <let name="this-segs" value="if (@seg) then normalize-space(replace(@seg,'\?','')) else ()"/>
         <let name="seg-count" value="for $i in $src-segmented-data-for-this-div-ref/tan:div return count($i/tan:seg)"/>
         <let name="seg-ceiling" value="min($seg-count)"/>
         <let name="this-seg-max" value="if (exists($this-segs)) then tan:max-integer($this-segs) else 1"/>
         <let name="this-seg-min-last" value="if (exists($this-segs) and exists($seg-ceiling)) 
            then tan:min-last($this-segs,$seg-ceiling) else 1"/>
         <!-- START TESTING BLOCK -->
         <let name="test1" value="$this-src-list"/>
         <let name="test2" value="$src-impl-div-types"/>
         <let name="test3" value="tan:normalize-impl-refs(@ref, 3)"/>
         <report test="false()">Testing. [VAR1: <value-of select="$test1"/>] [VAR2: <value-of
            select="$test2"/>] [VAR3: <value-of select="$test3"/>]</report>
         <!-- END TESTING BLOCK -->
         <report test="$ref-has-errors">Every ref cited must be found in every source (<value-of
               select="if (exists($div-type-mismatches)) then
                     concat('faulty div types:', string-join($div-type-mismatches,' '),'; acceptable values: ',string-join($valid-div-types,' '))
                  else
                     ()"/>).</report>
         <report
            test="$qty-of-srcs-with-implicit-div-types gt 0 and $qty-of-srcs-with-implicit-div-types ne count($this-src-list)"
            >Sources that take implicit div type references may not be mixed with those that take explicit ones.</report>
         <report test="exists($duplicate-sibling)" tan:does-not-apply-to="anchor-div-ref">Sibling div-refs may not duplicate each other.</report>
         <report test="if (exists($this-segs)) then (($this-seg-max gt $seg-ceiling) or ($this-seg-min-last lt 1)) 
            else false()">Every segment cited must appear in every div in every source (divs chosen have
            <value-of select="$seg-ceiling"/> segments max)</report>
         <report test="if (exists($this-segs)) then $seg-count = 1 else false()">@seg should not be
            used on a div that has not been split</report>
         <report test="if (exists($this-segs)) then $seg-count = 0 else false()">@seg may be used
            only with leaf divs</report>
         <report test="$is-anchor and count($this-src-list) gt 1" tan:does-not-apply-to="div-ref">An anchor div ref must point to
            only one source.</report>
         <report test="$is-anchor and (some $i in ($anchor-is-realigned) satisfies $i)" tan:does-not-apply-to="div-ref">An anchor may not be
            realigned by a div ref.</report>
         <report test="not($is-anchor) and $is-being-realigned and (some $i in ($div-ref-is-anchored) satisfies $i)" tan:does-not-apply-to="anchor-div-ref">An
            anchor may not be realigned by a div ref.</report>
         <report
            test="(parent::tan:align[not(@exclusive)]) and count($this-src-list) gt 1"
            tan:applies-to="align">Any @src of a child of an &lt;align> with no @exclusive may cite no more than
            one source.</report>
         <report test="@cont and not(following-sibling::tan:div-ref)" tan:applies-to="cont">Any &lt;div-ref> taking 
            @cont must be followed by at least one other &lt;dvi-ref>.</report>
      </rule>

   </pattern>

   <!-- FUNCTIONS -->
   <xsl:include href="../functions/TAN-A-div-functions.xsl"/>
</schema>
