<?xml version="1.0" encoding="UTF-8"?>
<pattern xmlns="http://purl.oclc.org/dsdl/schematron" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" id="class-2">
   <title>Schematron tests for class 2 TAN files.</title>

   <rule context="*">
      <let name="this-name" value="name(.)"/>
      <let name="this-q" value="count(preceding-sibling::*[name(.) = $this-name]) + 1"/>
      <let name="this-q-ref" value="tan:q-ref(.)"/>
      <let name="this-checked-for-errors"
         value="tan:get-via-q-ref($this-q-ref, $self-prepped)"/>
      <let name="has-include-or-which-attr" value="exists(@include) or exists(@which)"/>
      <let name="relevant-fatalities"
         value="
            if ($has-include-or-which-attr = true()) then
               $this-checked-for-errors//tan:fatal
            else
               $this-checked-for-errors/tan:fatal"/>
      <let name="relevant-errors"
         value="
            if ($has-include-or-which-attr = true()) then
               $this-checked-for-errors//tan:error
            else
               $this-checked-for-errors/tan:error"/>
      <let name="relevant-warnings"
         value="
            if ($has-include-or-which-attr = true()) then
               $this-checked-for-errors//tan:warning
            else
               $this-checked-for-errors/tan:warning"/>
      <let name="help-requested"
         value="
            if ($has-include-or-which-attr = true()) then
               $this-checked-for-errors//tan:help
            else
               $this-checked-for-errors/tan:help"/>
      <report test="exists($relevant-fatalities)" role="fatal">
         <value-of select="$relevant-fatalities/tan:rule"/></report>
      <report test="exists($relevant-errors)" sqf:fix="errors">
         <value-of select="tan:error-report($relevant-errors)"/></report>
      <report test="exists($relevant-warnings)" role="warning">[<value-of
            select="$relevant-warnings/@xml:id"/>] <value-of select="$relevant-warnings/tan:message"
         /></report>
      <report test="exists($help-requested)" role="warning" sqf:fix="help">
         <value-of select="$help-requested/tan:message"/>
      </report>
   </rule>
</pattern>
