<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" queryBinding="xslt2">
   <title>Tests for TAN-A-tok files.</title>
   <ns prefix="tan" uri="tag:textalign.net,2015:ns"/>
   <ns prefix="tei" uri="http://www.tei-c.org/ns/1.0"/>
   <ns prefix="xs" uri="http://www.w3.org/2001/XMLSchema"/>

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
      <active pattern="A-tok-quarter"/>
   </phase>
   <phase id="half">
      <active pattern="core"/>
      <active pattern="class-2-quarter"/>
      <active pattern="class-2-half"/>
      <active pattern="A-tok-quarter"/>
      <active pattern="A-tok-half"/>
   </phase>
   <phase id="full">
      <active pattern="core"/>
      <active pattern="class-2-quarter"/>
      <active pattern="class-2-half"/>
      <active pattern="class-2-full"/>
      <active pattern="A-tok-quarter"/>
      <active pattern="A-tok-half"/>
      <active pattern="A-tok-full"/>
   </phase>
   
   <pattern id="A-tok-quarter"
      xmlns:sqf="http://www.schematron-quickfix.com/validator/process">
      <let name="head-inclusion" value="/tan:TAN-A-tok/tan:head/tan:inclusion[@xml:id = following-sibling::tan:source/@include]"/>
      <let name="incl-1st-loc-avail" value="tan:first-loc-available($head-inclusion)"/>
      <let name="incl-1st-da" value="doc(resolve-uri($incl-1st-loc-avail, $doc-uri))"/>
      <let name="incl-1st-da-resolved" value="tan:resolve-doc($incl-1st-da)"/>
      <rule context="tan:declarations">
         <let name="children-names" value="for $i in * return name($i)"/>
         <let name="incl-declarations"
            value="distinct-values(for $i in $incl-1st-da-resolved//tan:declarations/*
               return
                  name($i))"/>
         <let name="missing-declarations" value="$incl-declarations[not(. = $children-names)]"/>
         <!--<assert
            test="every $i in $incl-declarations
                  satisfies *[name(.) = $i]"
            >Every declaration invoked by the head inclusion must be repeated here (<value-of
               select="$incl-declarations"/>)</assert>-->
         <report test="exists($missing-declarations) and exists($head-inclusion)"
            sqf:fix="add-declaration">In a TAN-A-tok file, if there is a &lt;source>/@include, then an
            entire set of sources are being imported, and, consequently, every declaration in the
            inclusion must also be explicitly included in the host file (missing: <value-of select="$missing-declarations"
            />)</report>
         <sqf:fix id="add-declaration">
            <sqf:description>
               <sqf:title>Add declaration</sqf:title>
               <sqf:p>Choosing this option will insert the first missing child of the declarations
                  element. If multiple declarations are missing, repeat as needed.</sqf:p>
            </sqf:description>
            <sqf:add target="{$missing-declarations[1]}" node-type="element" match="."
               position="first-child" select="//tan:source[1]/@include">
            </sqf:add>
         </sqf:fix>
         <!--<report test="$first-incl-doc-resolved//tan:rename-div-ns and not(tan:rename-div-ns[@include])">The source 
            document renames the div @n's. That declaration should be included here as well.
         </report>-->
      </rule>
      <rule context="*[parent::tan:declarations]">
         <report test="exists($head-inclusion) and not(@include)" sqf:fix="replace-with-inclusion"
            tan:does-not-apply-to="declarations">In a TAN-A-tok file, if there is a source/@include,
            then an entire set of sources are being imported, and, consequently, every declaration
            in the inclusion must also be included. </report>
         <sqf:fix id="replace-with-inclusion">
            <sqf:description>
               <sqf:title>Replace with inclusion</sqf:title>
               <sqf:p>Choosing this option will replace a child element of declarations with one 
                  that specifies @include to point to the value of source/@include</sqf:p>
            </sqf:description>
            <sqf:delete match="*"/>
            <sqf:delete match="@*"/>
            <sqf:add match="." node-type="attribute"
               target="include"><value-of select="$head-inclusion/@xml:id"/></sqf:add>
         </sqf:fix>
      </rule>
   </pattern>
   <pattern id="A-tok-half"></pattern>
   <pattern id="A-tok-full"></pattern>
   <!-- FUNCTIONS -->
   <xsl:include href="../functions/TAN-A-tok-functions.xsl"/>
</schema>
