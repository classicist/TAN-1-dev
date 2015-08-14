<?xml version="1.0" encoding="UTF-8"?>
<!-- to do: 
   Report on tan:align[@distribute = true] and tan:realign: children div-ref/(@ref,@seg), grouped by work, must 
      point to the same number of atomic references, so that they can be distributed one to one.
   Report on @seg: every @ref in the parent element must point to a leaf div.
   Report on @seg: for every ref in every source, a @seg's number may not exceed the number of splits + 1.
-->
<schema xmlns="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
   <title>Schematron ests for TAN-A-div files.</title>
   <ns prefix="tan" uri="tag:textalign.net,2015:ns"/>
   <ns prefix="tei" uri="http://www.tei-c.org/ns/1.0"/>
   <ns prefix="xs" uri="http://www.w3.org/2001/XMLSchema"/>
   <ns prefix="xsl" uri="http://www.w3.org/1999/XSL/Transform"/>

   <include href="TAN-core.sch"/>
   <include href="TAN-class-2.sch"/>
   <pattern>
      <rule context="tan:equate-works">
         <let name="this-src-list" value="tan:src-ids-to-nos(@src)"/>
         <let name="this-src-work-equivs"
            value="for $i in (2 to count($this-src-list)),
                  $j in (1 to ($i - 1))
               return
                  if ($src-1st-da-heads[$this-src-list[$i]]/tan:declarations/tan:work/tan:IRI/text() = $src-1st-da-heads[$this-src-list[$j]]/tan:declarations/tan:work/tan:IRI/text())
                  then
                     concat($src-ids[$this-src-list[$i]], ' = ', $src-ids[$this-src-list[$j]])
                  else
                     ()"/>
         <report test="exists($this-src-work-equivs)">Sources already share work IRIs. <value-of
               select="string-join($this-src-work-equivs, ', ')"/>. No equate-works is
            needed.</report>
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
         <report test="exists($this-src-div-type-equivs)">Sources' div types already share IRIs.
               <value-of select="string-join($this-src-div-type-equivs, ', ')"/>. No
            equate-div-types is needed.</report>
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
         <report test="exists($this-is-duplicate)">Duplicate div-type-ref (<value-of
               select="string-join($this-is-duplicate, ', ')"/>).</report>
      </rule>
      <rule context="tan:split-leaf-div-at">
         <let name="all-splits" value="for $i in tan:tok return tan:pick-tokenized-prepped-class-1-data($i)"/>
         <assert test="//tan:tokenization">If a leaf div is to be split, there must be at least one
            tokenization under TAN-A-div/head/ declarations/filter.</assert>
      </rule>
      <rule context="tan:tok">
         <let name="these-splits" value="tan:pick-tokenized-prepped-class-1-data(.)"/>
         <!-- START TESTING BLOCK -->
         <let name="test1" value="$these-splits//@*"/>
         <let name="test2" value="$these-splits"/>
         <let name="test3" value="true()"/>
         <report test="false()">Testing. [VAR1: <value-of select="$test1"/>] [VAR2: <value-of
            select="$test2"/>] [VAR3: <value-of select="$test3"/>]</report>
         <!-- END TESTING BLOCK -->
         <!--<report test="some $i in $is-duplicate satisfies $i = true()">Splitting a leaf div more
            than once in the same place is not allowed.</report>-->
      </rule>
      <rule context="tan:realign">
         <let name="these-srcs"
            value="for $i in .//@src
               return
                  tokenize($i, '\s+')"/>
         <let name="these-works"
            value="for $i in $these-srcs
               return
                  $equate-works[index-of($src-ids, $i)]"/>
         <report test="count(distinct-values($these-works)) ne 1">realign sources must all share the
            same work (<value-of select="count(distinct-values($these-works))"/> works currently
            referred to)</report>
      </rule>
      <rule context="tan:align">
         <let name="this-src-list" value="for $i in tan:div-ref return tan:src-ids-to-nos($i/@src)"/>
         <let name="this-work-list" value="for $i in $this-src-list return $equate-works[$i]"/>
         <report test="if (@distribute) then count(distinct-values($this-work-list)) eq 1 else false()">@distribute
            has no effect on an align that invokes only one work</report>
      </rule>
      <rule context="tan:div-ref">
         <let name="this" value="."/>
         <let name="this-src-list" value="tan:src-ids-to-nos(@src)"/>
         <let name="this-refs-norm"
            value="for $i in $this-src-list
               return
                  if ($i = $src-impl-div-types) then
                     tan:normalize-impl-refs(@ref, $i)
                  else
                     tan:normalize-refs(@ref)"/>
         <let name="this-src-qty-with-implicit-div-types"
            value="count($this-src-list[. = $src-impl-div-types])"/>
         <let name="src-ref-subset"
            value="tan:pick-prepped-class-1-data($this-src-list, $this-refs-norm)"/>
         <let name="duplicate-sibling"
            value="for $i in (preceding-sibling::node(),
               following-sibling::node())
               return
                  if (deep-equal($this, $i)) then
                     true()
                  else
                     ()"/>
         <let name="ref-has-errors" value="matches($this-refs-norm,'!!error')"/>
         <!-- need to convert this from :seg concept to @seg -->
         <!--<let name="this-refs-norm-no-seg"
            value="for $i in $this-refs-norm
               return
                  string-join((for $j in tokenize($i, '\s+-\s+')
                  return
                     if (matches($j, ':seg.\d+$', '') and (for $k in $this-src-list
                     return
                        exists($src-1st-da-data[$k]/tan:div[@lang][@ref = replace($j, ':seg.\d+$', '')]))) then
                        replace($j, ':seg.\d+$', '')
                     else
                        $j), ' - ')"/>-->
         <!--<let name="src-ref-mismatch"
            value="for $i in $this-src-list
               return
                  for $j in $this-refs-norm
                  return
                     for $k in tokenize($j, '\s+-\s+')
                     return
                        if (exists($src-1st-da-data[$i]/tan:div[@ref = $k])) then
                           ()
                        else
                           concat($src-ids[$i], ':', $k)"/>-->
         <!--<let name="ref-seg-test-1" value="tokenize(@ref,'\s+[-,]\s+')"/>
         <let name="ref-seg-test-2" value="for $i in $ref-seg-test-1 return replace(replace($i,'(.+)\Wseg\W\d+','$1'),'\W','.')"/>
         <let name="ref-seg-test-exp-1" value="for $i in $this-src, $j in $ref-seg-test-2 return 
            $all-splits-experiment[min(index-of($experimental-all-div-flatrefs,concat($i,' ',$j)))]"/>
         <let name="ref-seg-test-exp-2" value="for $i in $this-src,$j in $ref-seg-test-1 return number(replace($j,'.+\Wseg\W(\d+)','$1'))"></let>
         <let name="ref-seg-test-exp-3" value="for $i in (1 to count($ref-seg-test-exp-1)) return
            if ($ref-seg-test-exp-2[$i] - 1 > number($ref-seg-test-exp-1[$i])) then false() else true()"></let>-->
         <!--<report test="exists($src-ref-mismatch)">Every ref cited must be found in every source
               (<value-of select="$src-ref-mismatch"/>).</report>-->
         <!--<report test="(../../tan:split-leaf-div-at) and (some $i in $ref-seg-test-exp-3 satisfies $i = false())">There have not been enough splits made to accommodate that
            number of segments.
         </report>-->
         <report test="$src-ref-subset/tan:div/@error or $ref-has-errors">Every
            ref cited must be found in every source (<value-of
               select="for $i in $src-count,
                     $j in $src-ref-subset[$i]/tan:div[@error]
                  return
                     concat($src-ids[$i], ': ', $j/@ref)"
            /><value-of select="if ($ref-has-errors) then $this-refs-norm else ()"/>).</report>
         <report
            test="$this-src-qty-with-implicit-div-types gt 0 and $this-src-qty-with-implicit-div-types ne count($this-src-list)"
            >Either all sources or no sources must be declared in implicit-div-type-refs</report>
         <report test="exists($duplicate-sibling)">No div-ref may have a duplicate sibling.</report>
      </rule>
   </pattern>

   <!-- FUNCTIONS -->
   <xsl:include href="../functions/TAN-A-div-functions.xsl"/>
</schema>
