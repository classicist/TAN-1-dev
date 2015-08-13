<?xml version="1.0" encoding="UTF-8"?>
<pattern xmlns="http://purl.oclc.org/dsdl/schematron" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
   xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
   <title>Core Schematron tests for all TAN files.</title>
   <let name="schema-version-major" value="1"/>
   <let name="schema-version-minor" value="'dev'"/>
   <let name="now" value="tan:dateTime-to-decimal(current-dateTime())"/>
   <rule context="/*">
      <report test="true()" role="warning">This version of TAN is unstable and unpublished. Use it
         at your own risk.</report>
   </rule>
   <rule context="text()">
      <let name="this-raw-char-seq" value="tokenize(replace(.,'(.)','$1 '),' ')"/>
      <let name="this-nfc-char-seq" value="tokenize(replace(normalize-unicode(.),'(.)','$1 '),' ')"/>
      <let name="this-non-nfc-seq"
         value="distinct-values($this-raw-char-seq[not(.=$this-nfc-char-seq)])"/>
      <assert test=". = normalize-unicode(.)" sqf:fix="normalize-unicode">All text needs to be
         normalized (NFC). Errors: <value-of
            select="for $i in $this-non-nfc-seq return concat($i,' (U+',
            tan:dec-to-hex(string-to-codepoints($i)),') at ',
            string-join(for $j in index-of($this-raw-char-seq,$i) return string($j),' ')),' '"
         /></assert>
      <sqf:fix id="normalize-unicode">
         <sqf:description>
            <sqf:title>Convert to normalized (NFC) Unicode</sqf:title>
         </sqf:description>
         <sqf:stringReplace match="." regex=".+"><value-of select="normalize-unicode(.)"
            /></sqf:stringReplace>
      </sqf:fix>
   </rule>
   <rule context="@TAN-version">
      <let name="ver" value="tokenize(.,'\W+')"/>
      <report test="number($ver[1]) != $schema-version-major"
         sqf:fix="correct-major-version-only correct-whole-version">Should be schema major version
            <value-of select="$schema-version-major"/></report>
      <report test="$ver[2] and $ver[2] != $schema-version-minor"
         sqf:fix="correct-major-version-only correct-whole-version">Should be schema minor version
            <value-of select="$schema-version-minor"/></report>
      <sqf:fix id="correct-major-version-only">
         <sqf:description>
            <sqf:title>Update to <value-of select="$schema-version-major"/></sqf:title>
         </sqf:description>
         <sqf:replace match="." target="TAN-version" node-type="attribute"><value-of
               select="$schema-version-major"/></sqf:replace>
      </sqf:fix>
      <sqf:fix id="correct-whole-version">
         <sqf:description>
            <sqf:title>Update to <value-of select="$schema-version-major"/>/<value-of
                  select="$schema-version-minor"/></sqf:title>
         </sqf:description>
         <sqf:replace match="." target="TAN-version" node-type="attribute"><value-of
               select="$schema-version-major"/>/<value-of select="$schema-version-minor"
            /></sqf:replace>
      </sqf:fix>
   </rule>
   <rule context="tan:head">
      <let name="is-in-progress" value="if (/*/*//@in-progress = 'false') then false() else true()"/>
      <report test="($is-in-progress = false()) and (not(tan:master-location))"
         sqf:fix="add-master-location-fixed add-master-location-relative">Any TAN file marked as
         being no longer in progress must have at least one master-location (after name and before
         rights-excluding-sources).</report>
      <sqf:fix id="add-master-location-fixed">
         <sqf:description>
            <sqf:title>Add master-location element after &lt;name&gt; with fixed URL</sqf:title>
         </sqf:description>
         <sqf:add node-type="element" target="master-location" position="after" match="tan:name"
               ><value-of select="$doc-uri"/></sqf:add>
      </sqf:fix>
      <sqf:fix id="add-master-location-relative">
         <sqf:description>
            <sqf:title>Add master-location element after &lt;name&gt; with relative URL</sqf:title>
         </sqf:description>
         <sqf:add node-type="element" target="master-location" position="after" match="tan:name"
               ><value-of select="replace($doc-uri,$doc-parent-directory,'')"/></sqf:add>
      </sqf:fix>
   </rule>
   <rule context="tan:master-location|tan:location">
      <let name="loc" value="text()"/>
      <let name="is-master-location" value="if (name() = 'master-location') then true() else false()"/>
      <let name="resource-type"
         value="if ($is-master-location) then 'master document' else name(..)"/>
      <let name="loc-uri" value="tan:resolve-url($loc)"/>
      <let name="loc-doc-is-available" value="doc-available($loc-uri)"/>
      <let name="loc-doc" value="if ($loc-doc-is-available) then doc($loc-uri) else ()"/>
      <let name="loc-ver-date-nodes" value="$loc-doc//*[(@when | @ed-when | @when-accessed)]"/>
      <let name="loc-ver-dates" value="$loc-ver-date-nodes/(@when | @ed-when | @when-accessed)"/>
      <let name="loc-ver-nos" value="for $i in $loc-ver-dates return tan:dateTime-to-decimal($i)"/>
      <let name="loc-ver-date-latest"
         value="if ($loc-doc-is-available) then $loc-ver-dates[index-of($loc-ver-nos,max($loc-ver-nos))[1]] else ()"/>
      <let name="loc-ver-date-nodes-latest"
         value="$loc-ver-date-nodes[(@when | @ed-when | @when-accessed) = $loc-ver-date-latest]"/>
      <let name="when-accessed" value="tan:dateTime-to-decimal(@when-accessed)"/>
      <let name="is-location-of-tan-file" value="tan:must-refer-to-external-tan-file(.)"/>
      <let name="is-first-da-location"
         value="if ($loc-doc-is-available and 
         not((preceding-sibling::tan:location, preceding-sibling::tan:master-location)[doc-available(tan:resolve-url(.))])) 
         then true() else false()"/>
      <let name="is-in-progress"
         value="if ($loc-doc/*/(tan:body, tei:text/tei:body)/@in-progress = 'false') then false() else true()"/>
      <let name="updates-should-be-checked"
         value="if (../tan:relationship = ('old version') or matches(../tan:relationship,'edition$')) then true() else false()"/>
      <!-- START TESTING BLOCK -->
      <let name="test1" value="$is-location-of-tan-file"/>
      <let name="test2" value="$is-first-da-location"/>
      <let name="test3" value="$is-in-progress"/>
      <report test="false()">Testing. var1: <value-of select="$test1"/> var2: <value-of
            select="$test2"/> var3: <value-of select="$test3"/></report>
      <!-- END TESTING BLOCK -->
      <report role="warning" sqf:fix="replace-file"
         test="if (($loc-doc-is-available = true()) and (parent::tan:head)) then (max($loc-ver-nos) != max($doc-ver-nos)) else false()"
         >Version found in master location (<value-of select="$loc-ver-date-latest"/>) does not
         match this version (<value-of
            select="$doc-ver-dates[index-of($doc-ver-nos,max($doc-ver-nos))[1]]"/>)</report>
      <assert test="$loc-doc-is-available = true()" role="warn">The <value-of
            select="$resource-type"/> is either unavailable or is available but is not valid
         XML.</assert>
      <assert test="if (exists($loc-doc) and $is-master-location) then deep-equal(root(.),$loc-doc) else true()" role="warning">The
      current document does not match the master document</assert>
      <report role="warn"
         test="if ($is-location-of-tan-file and $is-first-da-location) 
         then $is-in-progress else false()"
         >Underlying TAN file is marked as being in progress (checked only against first document
         available)</report>
      <report sqf:fix="replace-with-current-date"
         test="if ($is-location-of-tan-file and $is-first-da-location and $updates-should-be-checked
         and exists($when-accessed)) 
         then (max($loc-ver-nos) gt $when-accessed) 
         else false()"
         role="warn">TAN file updated (<value-of select="$loc-ver-date-latest"/>) since last
         accessed (tested only against first location available) <value-of
            select="for $i in $loc-ver-date-nodes-latest return
            if (name($i) = ('comment','change')) then concat(name($i),': ',$i) else
            concat('edited: ',string-join(for $j in $i/ancestor-or-self::node()[name()] return concat(name($j),'[',string(count($j/preceding-sibling::node()[name(.) = name($j)]) + 1),']'),'/'))"
         /></report>
      <sqf:fix id="replace-with-current-date">
         <sqf:description>
            <sqf:title>Change date to today's date</sqf:title>
         </sqf:description>
         <sqf:replace match="@when-accessed" target="when-accessed" node-type="attribute">
            <value-of select="current-date()"/>
         </sqf:replace>
      </sqf:fix>
      <sqf:fix id="replace-file">
         <sqf:description>
            <sqf:title>Replace current tan:head and tan:body with tan:head and tan:body from file at
               master location</sqf:title>
         </sqf:description>
         <sqf:replace match="/*/tan:head" select="$loc-doc/*/tan:head"/>
         <sqf:replace match="/*/tan:body" select="$loc-doc/*/tan:body"/>
      </sqf:fix>
   </rule>
   <rule context="tan:see-also">
      <let name="this-relationship" value="normalize-space(tan:relationship)"/>
      <let name="must-point-to-external-tan"
         value="if ($this-relationship = $relationship-keywords-for-tan-files) then true() else false()"/>
      <let name="first-loc"
         value="tan:location[doc-available(.) or doc-available(concat($doc-parent-directory,.))][1]"/>
      <let name="first-doc"
         value="if (doc-available($first-loc)) then doc($first-loc) 
         else if (doc-available(concat($doc-parent-directory,$first-loc))) 
         then doc(concat($doc-parent-directory,$first-loc)) else ()"/>
      <let name="points-to-which-tan" value="name($first-doc/*)"/>
      <report test="$must-point-to-external-tan and not($points-to-which-tan = $all-root-names)"
         >Must point to TAN file (checked only against first location available). <value-of
            select="if (exists($points-to-which-tan)) 
               then concat('root element: ',$points-to-which-tan) else ()"
         /></report>
      <report
         test="$this-relationship = $relationship-keywords-for-tan-editions and $points-to-which-tan ne name(/*)"
         >The <value-of select="$this-relationship"/> must be the same TAN format (root element of
         target = <value-of select="$points-to-which-tan"/>).</report>
      <report
         test="$this-relationship = 'dependent' and not(document($first-loc)/*/tan:head/tan:source[tan:IRI = $doc-id])"
         >Dependent file has no source whose IRI matches this document's id.</report>
      <report
         test="$this-relationship = $relationship-keywords-for-tan-editions and $doc-id = $first-doc/*/@id"
         >The <value-of select="$this-relationship"/> cannot have the same @id value as this
         file.</report>
   </rule>
   <rule context="tan:relationship">
      <report test="not(tan:*) and not(text() = $relationship-keywords-all)">Unless you define a
         relationship through an IRI + name pattern, the value must be: <value-of
            select="string-join($relationship-keywords-all,', ')"/>
      </report>
   </rule>
   <rule context="tan:agent">
      <let name="all-agent-uris" value="concat(' ',string-join(../tan:agent/tan:IRI,' '))"/>
      <let name="match" value="matches($all-agent-uris,concat(' tag:',$tan-iri-namespace))"/>
      <assert test="$match">At least one agent must have an IRI with a tag URI whose namespace
         matches that of the URI name, <value-of select="$tan-iri-namespace"/></assert>
   </rule>
   <rule context="@when[parent::tan:*]|@ed-when|@when-accessed">
      <let name="this-time" value="tan:dateTime-to-decimal(.)"/>
      <report test="$this-time > $now">Future dates are not allowed (today's date and time is
            <value-of select="current-dateTime()"/>).</report>
      <assert test="(. castable as xs:dateTime) or (. castable as xs:date)"
         sqf:default-fix="current-date" sqf:fix="current-date">@<value-of select="name(.)"/> must be
         date or dateTime</assert>
      <sqf:fix id="current-date">
         <sqf:description>
            <sqf:title>Change date to today's date</sqf:title>
         </sqf:description>
         <sqf:replace match="." target="when" node-type="attribute" use-when="name(.) = 'when'">
            <value-of select="current-date()"/>
         </sqf:replace>
         <sqf:replace match="." target="ed-when" node-type="attribute"
            use-when="name(.) = 'ed-when'">
            <value-of select="current-date()"/>
         </sqf:replace>
         <sqf:replace match="." target="when-accessed" node-type="attribute"
            use-when="name(.) = 'when-accessed'">
            <value-of select="current-date()"/>
         </sqf:replace>
      </sqf:fix>
   </rule>
   <rule context="@when-to">
      <let name="when-from" value="tan:dateTime-to-decimal(../@when-from)"/>
      <let name="when-to" value="tan:dateTime-to-decimal(.)"/>
      <assert test="$when-to gt $when-from">Start date must precede end date.</assert>
   </rule>
   <rule
      context="@who|@ed-who|@roles|@src|@type[parent::tan:div|parent::tei:div]|@lexicon|@morphology|@reuse-type|@bitext-relation|@feature|@alignments">
      <!-- This rule is intended primarily to make sure that idrefs correspond
      to the correct elements -->
      <let name="referring-attribute"
         value="('who','ed-who','roles','src','type','lexicon','morphology','reuse-type','bitext-relation','feature','alignments')"/>
      <let name="referred-element"
         value="('agent','agent','role','source','div-type','lexicon','morphology','reuse-type','bitext-relation','feature','align')"/>
      <let name="this-attribute-name" value="name(.)"/>
      <let name="should-refer-to-which-element"
         value="$referred-element[index-of($referring-attribute,$this-attribute-name)]"/>
      <let name="idrefs" value="tokenize(.,'\s+')"/>
      <let name="idrefs-currently-target-what-element" value="for $n in $idrefs return name(id($n))"/>
      <assert
         test="every $k in $idrefs-currently-target-what-element satisfies $k = $should-refer-to-which-element"
            >@<value-of select="$this-attribute-name"/> must refer to <value-of
            select="$should-refer-to-which-element"/>s (<value-of
            select="/*/tan:head//*[name(.)=$should-refer-to-which-element]/@xml:id"/><value-of
            select="if (exists($idrefs-currently-target-what-element)) then concat('); currently points to ',string-join($idrefs-currently-target-what-element,' ')) else ''"
         />).</assert>
      <assert test="count($idrefs)=count(distinct-values($idrefs))">@<value-of
            select="$should-refer-to-which-element"/> must not contain duplicates</assert>
   </rule>
   <rule context="@regex-test|tan:pattern">
      <report test="matches(.,'\\[^nrtpPsSiIcCdDwW\\|.?*+(){}#x2D#x5B#x5D#x5E\]\[\^\-]')">Escape
         sequence not recognized by XML schema. See http://www.w3.org/TR/xmlschema-2/#regexs for
         details.</report>
   </rule>
   <rule context="tan:IRI">
      <let name="count" value="count(index-of($iris,.))"/>
      <let name="is-iri-of-tan-file" value="tan:must-refer-to-external-tan-file(.)"/>
      <let name="first-loc"
         value="../tan:location[doc-available(.) or doc-available(concat($doc-parent-directory,.))][1]"/>
      <let name="first-doc"
         value="if (doc-available($first-loc)) then doc($first-loc) 
         else if (doc-available(concat($doc-parent-directory,$first-loc))) 
         then doc(concat($doc-parent-directory,$first-loc)) else ()"/>
      <let name="first-da-iri-name" value="$first-doc/*/@id"/>
      <assert test="$count = 1">An IRI should appear only once in a TAN document.</assert>
      <report test="$is-iri-of-tan-file and not(text() = $first-da-iri-name)"
         sqf:fix="replace-with-tan-id">TAN id mismatch (expected: <value-of
            select="$first-da-iri-name"/>)</report>
      <sqf:fix id="replace-with-tan-id">
         <sqf:description>
            <sqf:title>Replace with TAN id of 1st document available</sqf:title>
         </sqf:description>
         <sqf:stringReplace match="./text()" regex=".+">
            <value-of select="$first-da-iri-name"/>
         </sqf:stringReplace>
      </sqf:fix>
   </rule>
   <!-- xsl:include provided below, commented out, in case validity needs to be checked; these
      fuctions are otherwise invoked through the master schematron files -->
   <!--<xsl:include href="TAN-core-functions.xsl"/>-->
</pattern>
