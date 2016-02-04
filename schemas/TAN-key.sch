<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" queryBinding="xslt2">
   <title>Tests for TAN-key files.</title>
   <ns prefix="tan" uri="tag:textalign.net,2015:ns"/>
   <ns prefix="tei" uri="http://www.tei-c.org/ns/1.0"/>
   <ns prefix="xs" uri="http://www.w3.org/2001/XMLSchema"/>
   <ns prefix="sqf" uri="http://www.schematron-quickfix.com/validator/process"/>
   <!-- common core below -->
   <include href="TAN-core.sch"/>
   <include href="TAN-class-4.sch"/>

   <!-- FUNCTIONS -->
   <xsl:include href="../functions/TAN-key-functions.xsl"/>
   <let name="all-names" value="$body//tan:name"/>
   <let name="duplicate-names" value="$all-names[index-of($all-names, .)[2]]"/>
   <let name="is-reserved-TAN-key"
      value="
         if (matches(/*/@id, '^tag:textalign.net,2015:tan-key:')) then
            true()
         else
            false()"/>
   <pattern>
      <rule context="tan:name">
         <let name="affected-elements"
            value="tokenize(ancestor::*[@affects-element][1]/@affects-element, '\s+')"/>
         <report
            test="not($is-reserved-TAN-key) and . = $TAN-keywords//tan:name[tokenize(ancestor::*[@affects-element][1]/@affects-element, '\s+') = $affected-elements]"
            >Names may not duplicate reserved TAN keywords for the affected element.</report>
         <report test=". = $duplicate-names">Names may not duplicate each other. </report>
      </rule>
      <rule context="@affects-element">
         <let name="these-elements" value="tokenize(., '\s+')"/>
         <assert
            test="
               every $i in $these-elements
                  satisfies $i = $TAN-elements-that-take-the-attribute-which/@name"
            >Items and groups must be about elements that take @which (<xsl:value-of
               select="$TAN-elements-that-take-the-attribute-which/@name"/>)</assert>
      </rule>
      <rule context="tan:IRI[parent::tan:item]">
         <let name="count" value="count(index-of($all-body-iris, .))"/>
         <assert test="$count = 1">Every IRI in invoked in the body of a TAN-key should be unique
            within the body.</assert>
      </rule>
   </pattern>

</schema>
