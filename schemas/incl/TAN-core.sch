<?xml version="1.0" encoding="UTF-8"?>
<pattern abstract="true"
   xmlns="http://purl.oclc.org/dsdl/schematron" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
   xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" id="tan-file-resolved">
   <title>Core Schematron tests for all TAN files.</title>
   <p>In this abstract pattern, the one parameter is $self-version, which admits the variable the
      user wishes to serve as a basis for the test against the original. Establishing matters this
      way means that a user can choose phases to validate either simply (and so quickly) or
      extensively(and so perhaps in a time-consuming manner) </p>
   <rule context="*">
      <!--<let name="this-name" value="name(.)"/>-->
      <!--<let name="this-q" value="count(preceding-sibling::*[name(.) = $this-name]) + 1"/>-->
      <let name="this-q-ref" value="tan:q-ref(.)"/>
      <let name="this-checked-for-errors"
         value="tan:get-via-q-ref($this-q-ref, $self-version)"/>
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
      <let name="relevant-info"
         value="
            if ($has-include-or-which-attr = true()) then
               $this-checked-for-errors//tan:info
            else
               $this-checked-for-errors/tan:info"
      />
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
            select="$relevant-warnings/@xml:id"/>] <value-of select="$relevant-warnings/(tan:message, tan:assert, tan:report)"
         /></report>
      <report test="exists($relevant-info)" role="info"><value-of
            select="$relevant-info/tan:message"/></report>
      <report test="exists($help-requested)" role="warning" sqf:fix="help">
         <value-of select="$help-requested/tan:message"/>
      </report>
      <sqf:group id="errors" use-when="$has-include-or-which-attr = false()">
         <sqf:fix id="replace-text"
            use-when="$has-include-or-which-attr = false() and exists($relevant-errors[@xml:id = ('tan04', 'tan10', 'cl104', 'cl111', 'cl112', 'cl113')])">
            <sqf:description>
               <sqf:title>Replace text with: <value-of
                  select="$relevant-errors[@xml:id = ('tan04', 'tan10', 'cl104', 'cl111', 'cl112', 'cl113')]/tan:fix"/></sqf:title>
            </sqf:description>
            <sqf:replace match="text()" select="$relevant-errors[@xml:id = ('tan04', 'tan10', 'cl104', 'cl111', 'cl112', 'cl113')]/tan:fix/text()"
            />
         </sqf:fix>
         <sqf:fix id="add-master-location-fixed"
            use-when="$has-include-or-which-attr = false() and exists($relevant-errors[@xml:id = 'tan02'])">
            <sqf:description>
               <sqf:title>Add master-location element after &lt;name&gt; with fixed URL</sqf:title>
               <sqf:p>Choosing this option will insert a master-location immediately after name,
                  with the absolute value of the current file's URL.</sqf:p>
            </sqf:description>
            <sqf:add position="after" select="$relevant-errors[@xml:id = 'tan02']/tan:fix/*"
               match="tan:name"/>
         </sqf:fix>
         <sqf:fix id="replace-IRI" use-when="exists($relevant-errors[@xml:id = 'loc02'])">
            <sqf:description>
               <sqf:title>Replace IRI with: <value-of
                  select="$relevant-errors[@xml:id = 'loc02']/tan:fix"/></sqf:title>
            </sqf:description>
            <sqf:replace match="tan:IRI"
               select="$relevant-errors[@xml:id = 'loc02']/tan:fix/tan:IRI"/>
         </sqf:fix>
         <sqf:fix id="replace-which-with-1st-val"
            use-when="exists($relevant-errors[@xml:id = 'whi01'])">
            <sqf:description>
               <sqf:title>Replace @which with <value-of
                  select="$relevant-errors[@xml:id = 'whi01']/tan:fix/tan:item[1]/tan:name[1]"
               /></sqf:title>
            </sqf:description>
            <sqf:replace match="@which" node-type="attribute" target="which"
               select="$relevant-errors[@xml:id = 'whi01']/tan:fix/tan:item[1]/tan:name[1]"/>
         </sqf:fix>
         <sqf:fix id="replace-which-with-2nd-val"
            use-when="exists($relevant-errors[@xml:id = 'whi01']/tan:fix/tan:item[2])">
            <sqf:description>
               <sqf:title>Replace @which with <value-of
                  select="$relevant-errors[@xml:id = 'whi01']/tan:fix/tan:item[2]/tan:name[1]"
               /></sqf:title>
            </sqf:description>
            <sqf:replace match="@which" node-type="attribute" target="which"
               select="$relevant-errors[@xml:id = 'whi01']/tan:fix/tan:item[2]/tan:name[1]"/>
         </sqf:fix>
         <sqf:fix id="current-date">
            <sqf:description>
               <sqf:title>Change date to today's date, <value-of select="current-date()"
               /></sqf:title>
               <sqf:p>If value is invalid, this quick fix will be made available, to replace the
                  content of with the current date.</sqf:p>
            </sqf:description>
            <sqf:replace match="@when" target="when" node-type="attribute" use-when="@when"
               select="current-date()"/>
            <sqf:replace match="@ed-when" target="ed-when" node-type="attribute" use-when="@ed-when"
               select="current-date()"/>
            <sqf:replace match="@when-accessed" target="when-accessed" node-type="attribute"
               use-when="@when-accessed" select="current-date()"/>
         </sqf:fix>
         <sqf:fix id="current-date-time">
            <sqf:description>
               <sqf:title>Change date to today's date + time, <value-of select="current-dateTime()"
               /></sqf:title>
               <sqf:p>If value is invalid, this quick fix will be made available, to replace the
                  content of with the current date.</sqf:p>
            </sqf:description>
            <sqf:replace match="@when" target="when" node-type="attribute" use-when="@when"
               select="current-dateTime()"/>
            <sqf:replace match="@ed-when" target="ed-when" node-type="attribute" use-when="@ed-when"
               select="current-dateTime()"/>
            <sqf:replace match="." target="when-accessed" node-type="attribute"
               use-when="@when-accessed" select="current-dateTime()"/>
         </sqf:fix>
         <sqf:fix id="add-new-element-with-id"
            use-when="exists($relevant-errors[@xml:id = 'tan05'])">
            <sqf:description>
               <sqf:title>Add &lt;<value-of
                  select="name(($relevant-errors[@xml:id = 'tan05']/tan:fix/*)[1])"/>> with @xml:id of
                  <value-of select="($relevant-errors[@xml:id = 'tan05']/tan:fix/*/@xml:id)[1]"
                  /></sqf:title>
            </sqf:description>
            <sqf:add
               match="(
               //*[name(.) = name(($relevant-errors[@xml:id = 'tan05']/tan:fix/*)[1])]
               )[last()]"
               position="after">
               <xsl:text>&#xA;</xsl:text>
               <xsl:copy-of select="($relevant-errors[@xml:id = 'tan05']/tan:fix/*)[1]"/>
            </sqf:add>
         </sqf:fix>
         <sqf:fix id="insert-IRI-name-pattern" use-when="exists($relevant-errors[@xml:id = 'tan08'])">
            <sqf:description>
               <sqf:title>Delete @href and insert IRI, name, and location</sqf:title>
            </sqf:description>
            <sqf:delete match="@href"/>
            <sqf:add>
               <xsl:for-each select="$relevant-errors[@xml:id = 'tan08']/tan:fix/*">
                  <xsl:text>&#xA;</xsl:text>
                  <xsl:copy-of select="."/>
               </xsl:for-each>
            </sqf:add>
         </sqf:fix>
      </sqf:group>
      <sqf:group id="help">
         <sqf:fix id="copy-elements-after">
            <sqf:description>
               <sqf:title>Copy <value-of select="name(($help-requested/tan:fix/*)[1])"/> nodes after
                  this one</sqf:title>
            </sqf:description>
            <sqf:add position="after">
               <xsl:for-each select="($help-requested/tan:fix/*)[1]">
                  <xsl:text>&#xa;</xsl:text>
                  <xsl:copy-of select="."/>
               </xsl:for-each>
            </sqf:add>
         </sqf:fix>
         
      </sqf:group>
   </rule>
</pattern>
