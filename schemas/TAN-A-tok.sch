<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" queryBinding="xslt2">
   <title>Tests for TAN-A-tok files.</title>
   <ns prefix="tan" uri="tag:textalign.net,2015:ns"/>
   <ns prefix="tei" uri="http://www.tei-c.org/ns/1.0"/>
   <ns prefix="xs" uri="http://www.w3.org/2001/XMLSchema"/>
   <!-- to do: new rule: context: @chars | assert: @chars may not be invoked for tokens that
      have combining characters
   -->

   <!-- common core below -->
   <include href="TAN-core.sch"/>
   <include href="TAN-class-2.sch"/>
   <pattern>
      <!-- placeholder for future tests on TAN-A-tok files -->
   </pattern>
   <!-- FUNCTIONS -->
   <xsl:include href="../functions/TAN-A-tok-functions.xsl"/>
</schema>
