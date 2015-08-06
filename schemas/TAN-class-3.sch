<?xml version="1.0" encoding="UTF-8"?>
<pattern xmlns="http://purl.oclc.org/dsdl/schematron"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process" 
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <title>Core tests for class 3 TAN files.</title>
    <let name="src-count" value="count(/*/tan:head/tan:source)"/>
    <rule context="tan:source">
        <report test="($src-count > 1) and (not(@xml:id))" sqf:fix="insert-id">Any TAN file with
            more than one source must provide an @xml:id to label the source.</report>
        <sqf:fix id="insert-id">
            <sqf:description>
                <sqf:title>Insert @xml:id</sqf:title>
            </sqf:description>
            <sqf:add node-type="attribute" match="." target="xml:id"/>
        </sqf:fix>
    </rule>
</pattern>
