<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
   xmlns:tan="tag:textalign.net,2015:ns" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xi="http://www.w3.org/2001/XInclude" xmlns:sch="http://purl.oclc.org/dsdl/schematron"
   fpi="tag:textalign.net,2015:schema:TAN-A-div.sch">
   <title>Schematron tests for TAN-A-div files.</title>
   <ns prefix="tan" uri="tag:textalign.net,2015:ns"/>
   <ns prefix="tei" uri="http://www.tei-c.org/ns/1.0"/>
   <ns prefix="xs" uri="http://www.w3.org/2001/XMLSchema"/>
   <ns prefix="xsl" uri="http://www.w3.org/1999/XSL/Transform"/>
   <include href="incl/TAN-core.sch"/>
   <phase id="basic">
      <active pattern="self-prepped"/>
   </phase>
   <phase id="verbose">
      <active pattern="self-analyzed"/>
   </phase>
   <pattern id="self-prepped" is-a="tan-file-resolved">
      <param name="self-version" value="$self-prepped"/>
   </pattern>
   <pattern id="self-analyzed" is-a="tan-file-resolved">
      <param name="self-version" value="tan:prep-verbosely($self-prepped, $sources-prepped)"/>
   </pattern>
   
   
   <!--<include href="TAN-class-2.sch"/>
   <include href="TAN-class-2-edit.sch"/>
   <include href="TAN-class-2-quarter.sch"/>
   <include href="TAN-class-2-half.sch"/>
   <include href="TAN-class-2-full.sch"/>-->
   <!-- <include href="incl/self-resolved-errors.sch"/> -->
   <!--<phase id="edit">
      <active pattern="class-2-edit"/>
      <active pattern="A-div-edit"/>
   </phase>
   <phase id="quarter">
      <active pattern="core"/>
      <active pattern="class-2"/>
      <active pattern="class-2-quarter"/>
      <active pattern="A-div-quarter"/>
      <!-\-<active pattern="self-resolved"/>-\->
   </phase>
   <phase id="half">
      <active pattern="core"/>
      <active pattern="class-2"/>
      <active pattern="class-2-quarter"/>
      <active pattern="class-2-half"/>
      <active pattern="A-div-quarter"/>
      <active pattern="A-div-half"/>
      <!-\-<active pattern="self-resolved"/>-\->
   </phase>
   <phase id="full">
      <active pattern="core"/>
      <active pattern="class-2"/>
      <active pattern="class-2-quarter"/>
      <active pattern="class-2-half"/>
      <active pattern="class-2-full"/>
      <active pattern="A-div-quarter"/>
      <active pattern="A-div-half"/>
      <active pattern="A-div-full"/>
      <!-\-<active pattern="self-resolved"/>-\->
   </phase>-->
   <!--<pattern id="A-div-edit">
      <let name="srcs-common-skeleton" value="$empty-doc"/>
      <let name="self-expanded-3" value="$empty-doc"/>
      <let name="defective-alignments"
         value="
            $srcs-common-skeleton//tan:div[@src][not(
            some $i in $self-expanded-3/tan:TAN-A-div/tan:body/tan:realign/*
               satisfies
               ($i/@src = tokenize(@src, '\s+') and $i/@ref = @ref))]"/>
      <rule context="tan:body" role="warning">
         <!-\-<report test="exists($defective-alignments)"
            sqf:fix="prepare-defective-refs-for-realignment">Defective alignments exist. The
            following refs are not found in every version of the work: <value-of
               select="
                  for $i in $defective-alignments
                  return
                     concat(($i/@ref),
                     ' [', $i/@src, ']')"
            />
         </report>-\->
         <sqf:fix id="prepare-defective-refs-for-realignment">
            <sqf:description>
               <sqf:title>Imprint a copy of defective divs, i.e., divs whose refs do not match in
                  every source</sqf:title>
            </sqf:description>
            <sqf:add match="(*[not(self::tan:align)])[last()]" position="after">
               <xsl:text>&#xA;</xsl:text>
               <realign xmlns="tag:textalign.net,2015:ns">
                  <xsl:for-each select="$defective-alignments">
                     <xsl:text>&#xA;</xsl:text>
                     <div-ref src="{@src}" ref="{@ref}"/>
                  </xsl:for-each>
               </realign>
            </sqf:add>
         </sqf:fix>
      </rule>

   </pattern>
   <pattern id="A-div-quarter">
      <let name="self-expanded-2" value="$empty-doc"/>
      <let name="equate-works" value="$self-expanded-2/tan:TAN-A-div/tan:body/tan:group[tan:work]"/>
      <let name="equate-div-types"
         value="$self-expanded-2/tan:TAN-A-div/tan:body/tan:group[tan:div-type]"/>
      <rule context="tan:equate-works">
         <let name="this-resolved" value="$empty-doc"/>
         <let name="src-help-requested"
            value="
               some $i in $this-resolved/*
                  satisfies tan:help-requested($i/@src)"/>
         <let name="these-srcs"
            value="
               for $i in $this-resolved
               return
                  distinct-values(tokenize(tan:normalize-text($i/@src), ' '))"/>
         <let name="sources-equated-multiply"
            value="$equate-works[tan:work/@src = $these-srcs]/tan:error[@xml:id = 'equ01']"/>
         <let name="sources-equated-redundantly"
            value="$equate-works[tan:work/@src = $these-srcs]/tan:error[@xml:id = 'equ02']"/>
         <let name="current-work-groups"
            value="
               for $i in $equate-works
               return
                  ('(', $i/@src, ')')"/>
         <!-\-<report test="exists($sources-equated-multiply)" role="warning"
               ><value-of select="$sources-equated-multiply/*"/></report>-\->
         <!-\-<report test="exists($sources-equated-redundantly)" role="warning"
               ><value-of select="$sources-equated-redundantly/*"/></report>-\->
         <!-\-<report test="$src-help-requested = true()"
            ><!-\\- If $help-trigger is typed in @src the validation 
            routine will return the current sources, grouped by shared IRIs -\\->Current
            sources, grouped by works: <value-of select="$current-work-groups"/></report>-\->
      </rule>
      <rule context="tan:equate-div-types" tan:applies-to="div-type-ref">
         <let name="this-resolved" value="$empty-doc"/>
         <let name="this-expanded" value="tan:expand-src-and-div-type-ref($this-resolved/*)"/>
         <let name="these-div-type-refs" value="$this-expanded/tan:div-type-ref"/>
         <let name="div-type-help-requested"
            value="
               some $i in $this-resolved/*
                  satisfies tan:help-requested($i)"/>
         <let name="div-types-equated-multiply"
            value="
               for $i in $these-div-type-refs,
                  $j in $equate-div-types[tan:error[@xml:id = 'equ01']]
               return
                  if ($j/tan:div-type[@src = $i/@src and @xml:id = $i/@div-type-ref]) then
                     $j
                  else
                     ()"
         />
         <let name="div-types-equated-redundantly"
            value="
               for $i in $these-div-type-refs,
                  $j in $equate-div-types[tan:error[@xml:id = 'equ02']]
               return
                  if ($j/tan:div-type[@src = $i/@src and @xml:id = $i/@div-type-ref]) then
                     $j
                  else
                     ()"
         />
         <let name="current-div-type-groups"
            value="
               for $i in $equate-div-types
               return
                  ('(',
                  string-join(for $j in $i/tan:div-type
                  return
                     (concat($j/@src, ': ', $j/@xml:id)), '; '), ')')"/>
         <!-\-<report test="exists($div-types-equated-multiply)" role="warning">
            <value-of select="$div-types-equated-multiply/*"/></report>-\->
         <!-\-<report test="exists($div-types-equated-redundantly)">
            <value-of select="$div-types-equated-redundantly/*"/></report>-\->
         <!-\-<report test="$div-type-help-requested = true()" tan:applies-to="div-type-ref"
            ><!-\\- If $help-trigger is placed in @div-type-ref the validation 
            routine will return all div types, grouped by common IRIs -\\->Current
            div types, grouped: <value-of select="$current-div-type-groups"/></report>-\->
      </rule>
      <rule context="tan:align | tan:realign">
         <let name="this-resolved" value="$empty-doc"/>
         <let name="this-expanded" value="tan:expand-src-and-div-type-ref($this-resolved/*)"/>
         <let name="distributed-items" value="$this-resolved[@distribute]"/>
         <let name="nonexclusive-items" value="$this-resolved[not(@exclusive)]"/>
         <let name="ranges-in-distributed-items"
            value="
               for $i in $distributed-items/*,
                  $j in tokenize(tan:normalize-refs($i/@ref), ' , ')
               return
                  if (matches($j, ' - ')) then
                     $j
                  else
                     ()"/>
         <let name="uneven-ranges-in-distributed-items"
            value="
               for $i in $ranges-in-distributed-items
               return
                  if (count(tokenize(tokenize($i, ' - ')[1], ' ')) = count(tokenize(tokenize($i, ' - ')[2], ' '))) then
                     ()
                  else
                     $i"/>
         <let name="cross-work-realignments"
            value="
               for $i in $this-expanded[self::tan:realign]
               return
                  if (count(distinct-values($equate-works[tan:work/@src = $i/*/@src]/@n)) gt 1) then
                     distinct-values($i/*/@src)
                  else
                     ()"/>
         <let name="single-div-ref-in-a-distributed-align"
            value="$this-expanded[self::tan:align][@distribute][count(tan:div-ref) = 1]"/>
         <let name="anchor-div-refs-with-multiples-sources"
            value="$this-resolved/tan:anchor-div-ref[matches(@src, '\s+')]"/>
         <let name="nonexclusive-aligns-with-multiple-sources"
            value="$nonexclusive-items/tan:div-ref[matches(@src, '\s+')]"/>
         <!-\-<report test="exists($uneven-ranges-in-distributed-items)"
            tan:applies-to="distribute div-ref anchor-div-ref ref">In any @ref whose values might be
            distributed, the starting and ending point for every range, i.e., references joined by a
            hyphen, must sit in the same level of hierarchy (<value-of
               select="$uneven-ranges-in-distributed-items"/>)</report>-\->
         <!-\-<report test="exists($cross-work-realignments)" tan:applies-to="div-ref"
            tan:does-not-apply-to="align">In any &lt;realign>, different sources in &lt;div-ref>s
            must belong to the same work by IRI definition or &lt;equate-works> (<value-of
               select="$cross-work-realignments"/>)</report>-\->
         <!-\-<report test="exists($single-div-ref-in-a-distributed-align)"
            tan:applies-to="distribute div-ref align realign">@distribute has no effect on only one
            &lt;div-ref>.</report>-\->
         <!-\-<report test="exists($anchor-div-refs-with-multiples-sources)"
            tan:applies-to="anchor-div-ref src realign" tan:does-not-apply-to="align"
            subject="tan:anchor-div-ref">@src in &lt;anchor-div-ref> may take only one
            value.</report>-\->
         <!-\-<report tan:does-not-apply-to="realign" tan:applies-to="src align div-ref"
            test="self::tan:align and exists($nonexclusive-aligns-with-multiple-sources)"
            >&lt;div-ref>s under &lt;align>s that are not exclusive may not have multiple values for
            @src.</report>-\->
      </rule>

   </pattern>
   <pattern id="A-div-half">
      <let name="all-refs" value="distinct-values($self-prepped/tan:TAN-T/tan:body//@ref)"/>
      <let name="orphan-refs"
         value="
            for $i in $all-refs
            return
               if (count($self-prepped/tan:TAN-T/tan:body//tan:div[@ref = $i]) = 1 and
               not($body/tan:realign[tan:div-ref[@ref = $i]])) then
                  $self-prepped/tan:TAN-T/tan:body//tan:div[@ref = $i]
               else
                  ()"/>
      <rule context="tan:realign">
         <!-\-<report test="tan:help-requested(.) and exists($orphan-refs)"
            sqf:fix="first-orphan all-orphans"
            ><!-\\- Requesting help on <realign> 
         with phase = "half" or higher returns @refs that are orphaned, and could be candidates for realignment -\\->
            Possible divs to realign: <value-of
               select="
                  for $i in $orphan-refs
                  return
                     concat(root($i)/*/@src, ' ', $i/@ref)"
            />
         </report>-\->
         <sqf:fix id="first-orphan">
            <sqf:description>
               <sqf:title>Set up first orphan to be reanchored</sqf:title>
            </sqf:description>
            <sqf:replace>
               <tan:realign>
                  <xsl:text>&#xA;</xsl:text>
                  <tan:anchor-div-ref src="" ref=""/>
                  <xsl:text>&#xA;</xsl:text>
                  <tan:div-ref src="{root($orphan-refs[1])/*/@src}" ref="{$orphan-refs[1]/@ref}"/>
                  <xsl:text>&#xA;</xsl:text>
               </tan:realign>
            </sqf:replace>
         </sqf:fix>
         <sqf:fix id="all-orphans">
            <sqf:description>
               <sqf:title>Set up all orphans to be reanchored</sqf:title>
            </sqf:description>
            <sqf:replace>
               <xsl:for-each select="$orphan-refs">
                  <tan:realign>
                     <xsl:text>&#xA;</xsl:text>
                     <tan:anchor-div-ref src="" ref=""/>
                     <xsl:text>&#xA;</xsl:text>
                     <tan:div-ref src="{root()/*/@src}" ref="{@ref}"/>
                     <xsl:text>&#xA;</xsl:text>
                  </tan:realign></xsl:for-each>
            </sqf:replace>
         </sqf:fix>
      </rule>
   </pattern>

   <pattern id="A-div-full">
      <!-\-<let name="srcs-segmented"
         value="
            tan:get-src-1st-da-segmented($self-expanded-3, if ($self-expanded-3/tan:TAN-A-div/tan:body/tan:split) then
               $srcs-tokenized
            else
               $self-prepped)"/>-\->
      <let name="srcs-segmented" value="$self-prepped[position() gt 1]"/>
      <!-\-<let name="srcs-segmented"
         value="tan:get-src-1st-da-segmented($self-expanded-4, $srcs-tokenized)"/>-\->
      <!-\-<let name="self-expanded-5" value="tan:get-self-expanded-5($self-expanded-4)"/>-\->
      <let name="srcs-realigned"
         value="tan:get-src-1st-da-realigned($self-expanded-3, $srcs-segmented)"/>
      <rule context="tan:align | tan:realign">
         <let name="this-name" value="name(.)"/>
         <let name="this-q" value="count(preceding-sibling::*[name() = $this-name]) + 1"/>
         <let name="distro-errors"
            value="$self-expanded-3/tan:TAN-A-div/tan:body/*[name() = $this-name][@q = $this-q][tan:error]"/>
         <let name="segment-errors"
            value="$self-expanded-3/tan:TAN-A-div/tan:body/*[name() = $this-name][@q = $this-q]/*/*[matches(@seg, '[-+]|^0$')]"/>
         <let name="repeated-anchors"
            value="
               for $i in $self-expanded-3/tan:TAN-A-div/tan:body/tan:realign[@q = $this-q]/tan:anchor-div-ref/tan:div
               return
                  $i/following::tan:anchor-div-ref[@src = $i/../@src]/tan:div[@ref = $i/@ref and (if (exists(@seg)) then
                     @seg = $i/@seg
                  else
                     true())]"
         />
         <!-\-<report test="exists($distro-errors)" tan:applies-to="distribute">When @distribute is
            invoked each child element must point to the same number of divs (unmatched: 
            <value-of
               select="
                  for $i in $distro-errors/(tan:anchor-div-ref, tan:div-ref)[not(tan:div)]
                  return
                     concat('[', string-join(($i/@src, $i/@ref, name($i/@seg), $i/@seg), ' '), ']')"
            />) </report>-\->
         <!-\-<report test="exists($segment-errors)" tan:applies-to="seg">@seg may not take values that
            exceed the range allowed (<value-of
               select="
                  for $i in $segment-errors
                  return
                     concat('[', string-join(($i/@src, $i/@ref, 'seg', $i/@seg), ' '), ']')"
            /></report>-\->
         <!-\-<report
            test="
               if (self::tan:realign) then
                  exists($repeated-anchors)
               else
                  false()"
            tan:applies-to="div-ref anchor-div-ref" tan:does-not-apply-to="align">An anchor may not
            be duplicated by a &lt;div-ref> (<value-of
               select="
                  for $i in $repeated-anchors
                  return
                     concat('[', string-join(($i/@src, $i/@ref, 'seg', $i/@seg), ' '), ']')"
            />
         </report>-\->
      </rule>
      <rule context="tan:div-ref">
         <let name="help-requested" value="tan:help-requested(.)"/>
         <let name="unaligned-divs-and-segs" value="tan:group-realigned-sources($srcs-realigned, 1)"/>
         <!-\-<report test="$help-requested"
            ><!-\\- If $help-trigger is placed in any attribute, validation will 
         provide a list of divs and segs that currently have no alignment against any other version of the work -\\->divs
            and segs that are not aligned: <value-of
               select="
                  for $i in distinct-values($unaligned-divs-and-segs/@src)
                  return
                     concat('[', $i, ': ',
                     string-join(for $j in $unaligned-divs-and-segs[@src = $i]
                     return
                        if ($j/tan:seg) then
                           concat($j/*/@ref, ' seg ', $j/*/@seg)
                        else
                           $j/*/@ref, ', '),
                     '] ')"
            /></report>-\->
      </rule>
   </pattern>-->

   <!-- FUNCTIONS -->
   <xsl:include href="../functions/TAN-A-div-functions.xsl"/>
</schema>
