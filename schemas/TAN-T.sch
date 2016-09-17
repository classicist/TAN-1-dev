<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" queryBinding="xslt2">
   <title>Tests for TAN-T files.</title>
   <ns prefix="tan" uri="tag:textalign.net,2015:ns"/>
   <ns prefix="tei" uri="http://www.tei-c.org/ns/1.0"/>
   <ns prefix="xs" uri="http://www.w3.org/2001/XMLSchema"/>
   <ns prefix="sqf" uri="http://www.schematron-quickfix.com/validator/process"/>
   <include href="incl/TAN-core.sch"/>
   <!--<phase id="basic">
      <active pattern="self-prepped"/>
   </phase>
   <phase id="verbose">
      <active pattern="self-analyzed"/>
   </phase>-->
   <pattern id="self-prepped" is-a="tan-file-resolved">
      <param name="self-version" value="$self-class-1-errors-marked"/>
   </pattern>
   <!--<pattern id="self-analyzed" is-a="tan-file-resolved">
      <!-\- as of September 2016, no verbose version of a TAN-T file has been developed -\->
      <param name="self-version" value="$self-class-1-errors-marked"/>
   </pattern>-->
   <!-- FUNCTIONS -->
   <xsl:include href="../functions/TAN-T-functions.xsl"/>
</schema>
