<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" queryBinding="xslt2">
   <title>Tests for TAN-X files.</title>
   <ns prefix="tan" uri="tag:textalign.net,2015:ns"/>
   <ns prefix="tei" uri="http://www.tei-c.org/ns/1.0"/>
   <ns prefix="xs" uri="http://www.w3.org/2001/XMLSchema"/>
   <ns prefix="sqf" uri="http://www.schematron-quickfix.com/validator/process"/>
   <!-- common core below -->
   <include href="../TAN-core.sch"/>

   <!-- FUNCTIONS -->
   <xsl:include href="../../functions/TAN-T-functions.xsl"/>

</schema>
