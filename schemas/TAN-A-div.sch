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

   <include href="TAN-core.sch"/>
   <include href="TAN-class-2-edit.sch"/>
   <include href="TAN-class-2-quarter.sch"/>
   <include href="TAN-class-2-half.sch"/>
   <include href="TAN-class-2-full.sch"/>
   <phase id="edit">
      <active pattern="class-2-edit"/>
   </phase>
   <phase id="quarter">
      <active pattern="core"/>
      <active pattern="class-2-quarter"/>
      <active pattern="A-div-quarter"/>
   </phase>
   <phase id="half">
      <active pattern="core"/>
      <active pattern="class-2-quarter"/>
      <active pattern="class-2-half"/>
      <active pattern="A-div-quarter"/>
      <active pattern="A-div-half"/>
   </phase>
   <phase id="full">
      <active pattern="core"/>
      <active pattern="class-2-quarter"/>
      <active pattern="class-2-half"/>
      <active pattern="class-2-full"/>
      <active pattern="A-div-quarter"/>
      <active pattern="A-div-half"/>
      <active pattern="A-div-full"/>
   </phase>
   <pattern id="A-div-quarter">
      <let name="equate-works" value="$self-expanded-2/tan:TAN-A-div/tan:body/tan:group[tan:work]"/>
      <let name="equate-div-types"
         value="$self-expanded-2/tan:TAN-A-div/tan:body/tan:group[tan:div-type]"/>
      <rule context="tan:equate-works">
         <let name="this-resolved" value="tan:resolve-include(.)"/>
         <let name="src-help-requested"
            value="
               some $i in $this-resolved
                  satisfies tan:help-requested($i/@src)"/>
         <let name="these-srcs"
            value="for $i in $this-resolved return distinct-values(tokenize(tan:normalize-text($i/@src), ' '))"/>
         <let name="sources-equated-multiply"
            value="$equate-works[@err-equ01][tan:work/@src = $these-srcs]"/>
         <let name="sources-equated-redundantly"
            value="$equate-works[@err-equ02][tan:work/@src = $these-srcs]"/>
         <let name="current-work-groups"
            value="
               for $i in $equate-works
               return
                  ('(', $i/@src, ')')"/>
         <report test="exists($sources-equated-multiply)" role="warning"><value-of
               select="$errors//*[@xml:id = 'equ01']"/></report>
         <report test="exists($sources-equated-redundantly)"><value-of
               select="$errors//*[@xml:id = 'equ02']"/></report>
         <report test="$src-help-requested = true()">Current sources, grouped by works: <value-of
               select="$current-work-groups"/></report>
      </rule>
      <rule context="tan:equate-div-types">
         <let name="this-resolved" value="tan:resolve-include(.)"/>
         <let name="this-expanded" value="tan:expand-src-and-div-type-ref($this-resolved)"/>
         <let name="these-div-type-refs" value="$this-expanded/tan:div-type-ref"/>
         <let name="div-type-help-requested"
            value="
               some $i in $this-resolved/*
                  satisfies tan:help-requested($i)"/>
         <let name="div-types-equated-multiply"
            value="
               for $i in $these-div-type-refs,
                  $j in $equate-div-types[@err-equ01]
               return
                  if ($j/tan:div-type[@src = $i/@src and @xml:id = $i/@div-type-ref]) then
                     $j
                  else
                     ()"/>
         <let name="div-types-equated-redundantly"
            value="
               for $i in $these-div-type-refs,
                  $j in $equate-div-types[@err-equ02]
               return
                  if ($j/tan:div-type[@src = $i/@src and @xml:id = $i/@div-type-ref]) then
                     $j
                  else
                     ()"/>
         <let name="current-div-type-groups"
            value="
               for $i in $equate-div-types
               return
                  ('(',
                  string-join(for $j in $i/tan:div-type
                  return
                     (concat($j/@src, ': ', $j/@xml:id)), '; '), ')')"/>
         <report test="exists($div-types-equated-multiply)" role="warning"><value-of
               select="$errors//*[@xml:id = 'equ01']"/></report>
         <report test="exists($div-types-equated-redundantly)"><value-of
               select="$errors//*[@xml:id = 'equ02']"/></report>
         <report test="$div-type-help-requested = true()">Current div types, grouped: <value-of
               select="$current-div-type-groups"/></report>
      </rule>
      <rule context="tan:align | tan:realign">
         <let name="this-resolved" value="tan:resolve-include(.)"/>
         <let name="this-expanded" value="tan:expand-src-and-div-type-ref($this-resolved)"/>
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
         <report test="exists($uneven-ranges-in-distributed-items)">In any @ref whose values might
            be distributed, the starting and ending point for every range (references joined by a
            hyphen) must sit in the same level of hierarchy (<value-of
               select="$uneven-ranges-in-distributed-items"/>)</report>
         <report test="exists($cross-work-realignments)">In any &lt;realign> sources must belong to
            the same work by IRI definition or &lt;equate-works> (<value-of
               select="$cross-work-realignments"/>)</report>
         <report test="exists($single-div-ref-in-a-distributed-align)">@distribute has no effect on
            an align that has only one &lt;div-ref>.</report>
         <report test="exists($anchor-div-refs-with-multiples-sources)" subject="tan:anchor-div-ref"
            >&lt;anchor-div-ref> may point to no more than one source.</report>
         <report test="self::tan:align and exists($nonexclusive-aligns-with-multiple-sources)"
            >&lt;div-ref>s under &lt;align>s that are not exclusive may not have multiple values for
            @src.</report>
      </rule>

   </pattern>
   <pattern id="A-div-half"> </pattern>

   <pattern id="A-div-full">
      <let name="srcs-segmented"
         value="tan:get-src-1st-da-segmented($self-expanded-4, $srcs-tokenized)"/>
      <let name="self-expanded-5" value="tan:get-self-expanded-5($self-expanded-4)"/>
      <let name="srcs-realigned"
         value="tan:get-src-1st-da-realigned($self-expanded-5, $srcs-segmented)"/>
      <rule context="tan:align | tan:realign">
         <let name="this-name" value="name(.)"/>
         <let name="this-q" value="count(preceding-sibling::*[name() = $this-name]) + 1"/>
         <let name="distro-errors"
            value="$self-expanded-5/tan:TAN-A-div/tan:body/*[name() = $this-name][@q = $this-q][@error]"/>
         <let name="segment-errors"
            value="$self-expanded-5/tan:TAN-A-div/tan:body/*[name() = $this-name][@q = $this-q]/*/*[matches(@seg, '[-+0]')]"/>
         <let name="repeated-anchors"
            value="
               for $i in $self-expanded-5/tan:TAN-A-div/tan:body/tan:realign[@q = $this-q],
                  $j in $i/tan:group/tan:anchor-div-ref
               return
                  $i/tan:group/tan:div-ref[@src = $j/@src and @ref = $j/@ref and @seg = $j/@seg]"/>
         <report test="exists($distro-errors)">Distribution enforced: each source must have the same
            number of single references (unmatched: <value-of
               select="
                  for $i in $distro-errors//tan:div-ref
                  return
                     concat('[', string-join(($i/@src, $i/@ref, 'seg', $i/@seg), ' '), ']')"
            />) </report>
         <report test="exists($segment-errors)">@seg may not take values that exceed the range
            allowed (<value-of
               select="
                  for $i in $segment-errors
                  return
                     concat('[', string-join(($i/@src, $i/@ref, 'seg', $i/@seg), ' '), ']')"
            /></report>
         <report test="self::tan:realign and exists($repeated-anchors)">An anchor may not be
            duplicated by an &lt;div-ref> (<value-of
               select="
                  for $i in $repeated-anchors
                  return
                     concat('[', string-join(($i/@src, $i/@ref, 'seg', $i/@seg), ' '), ']')"
            />
         </report>
      </rule>
      <rule context="tan:div-ref">
         <let name="help-requested" value="tan:help-requested(.)"/>
         <let name="unaligned-divs-and-segs" value="tan:group-realigned-sources($srcs-realigned, 1)"/>
         <report test="$help-requested">divs and segs that are not aligned: <value-of
               select="
                  for $i in distinct-values($unaligned-divs-and-segs/@src)
                  return
                     concat('[', $i, ': ',
                     string-join(for $j in $unaligned-divs-and-segs[@src = $i]
                     return
                        if ($j/tan:seg) then
                           concat($j/*/@ref, ' seg ', $j/*/@seg)
                        else
                           $j/*/@realigned-ref, ', '),
                     '] ')"
            /></report>
      </rule>
   </pattern>

   <!-- FUNCTIONS -->
   <xsl:include href="../functions/TAN-A-div-functions.xsl"/>
</schema>
