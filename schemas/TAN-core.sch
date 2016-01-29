<?xml version="1.0" encoding="UTF-8"?>
<!-- TO DO: 
   [priority low] collapse tan:agent and *[@include] so that tan:agent can be explicated -->
<pattern xmlns="http://purl.oclc.org/dsdl/schematron" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
   xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
   <title>Core Schematron tests for all TAN files.</title>
   <let name="now" value="tan:dateTime-to-decimal(current-dateTime())"/>
   <rule context="/*" tan:applies-to="TAN-A-div TAN-A-tok">
      <report test="true()" role="warning"
         sqf:fix="get-morph-local get-morph-abs get-tok-local get-tok-abs get-incl-local get-incl-abs get-source-local get-source-abs"
         >This version of TAN is unstable and unpublished. Use it at your own risk.</report>
      <sqf:fix id="get-source-local">
         <sqf:description>
            <sqf:title>Get local source element with this document's IRI + name pattern</sqf:title>
            <sqf:p>Suppose you find a TAN file that you wish to make a source for another. Selecting
               this option will insert a tan:source element as the next child, complete with the
               appropriate values for tan:IRI and tan:name, and with a tan:location/@href that
               points to the local directory.</sqf:p>
         </sqf:description>
         <sqf:add match="tan:head" position="before">
            <source xmlns="tag:textalign.net,2015:ns"
               xml:id="{replace($doc-uri,'.*/([^/]+$)','$1')}">
               <IRI>
                  <xsl:value-of select="../@id"/></IRI>
               <name><xsl:value-of select="tan:name"/></name>
               <location when-accessed="{current-date()}"
                  href="{replace($doc-uri, '.*/([^/]+$)', '$1')}"/>
            </source>
         </sqf:add>
      </sqf:fix>
      <sqf:fix id="get-source-abs">
         <sqf:description>
            <sqf:title>Get absolute source element with this document's IRI + name
               pattern</sqf:title>
            <sqf:p>As above, but with an absolute URL.</sqf:p>
         </sqf:description>
         <sqf:add match="tan:head" position="before">
            <source xmlns="tag:textalign.net,2015:ns"
               xml:id="{replace($doc-uri,'.*/([^/]+$)','$1')}">
               <IRI>
                  <xsl:value-of select="../@id"/></IRI>
               <name><xsl:value-of select="tan:name"/></name>
               <location when-accessed="{current-date()}" href="{$doc-uri}"/>
            </source>
         </sqf:add>
      </sqf:fix>
      <sqf:fix id="get-incl-local">
         <sqf:description>
            <sqf:title>Get local inclusion element with this document's IRI + name
               pattern</sqf:title>
            <sqf:p>Suppose you find a TAN file that has elements you want to automatically include
               in another. Selecting this option will insert a tan:include element as the next
               child, complete with the appropriate values for tan:IRI and tan:name, and with a
               tan:location/@href that points to the local directory.</sqf:p>
         </sqf:description>
         <sqf:add match="tan:head" position="before">
            <inclusion xml:id="{replace(base-uri(),'.*/([^/]+$)','$1')}"
               xmlns="tag:textalign.net,2015:ns">
               <IRI>
                  <xsl:value-of select="../@id"/></IRI>
               <name><xsl:value-of select="tan:name"/></name>
               <location when-accessed="{current-date()}"
                  href="{replace($doc-uri, '.*/([^/]+$)', '$1')}"/>
            </inclusion>
         </sqf:add>
      </sqf:fix>
      <sqf:fix id="get-incl-abs">
         <sqf:description>
            <sqf:title>Get absolute inclusion element with this document's IRI + name
               pattern</sqf:title>
            <sqf:p>As above, but with an absolute URL.</sqf:p>
         </sqf:description>
         <sqf:add match="tan:head" position="before">
            <inclusion xml:id="{replace(base-uri(),'.*/([^/]+$)','$1')}"
               xmlns="tag:textalign.net,2015:ns">
               <IRI>
                  <xsl:value-of select="../@id"/></IRI>
               <name><xsl:value-of select="tan:name"/></name>
               <location when-accessed="{current-date()}" href="{$doc-uri}"/>
            </inclusion>
         </sqf:add>
      </sqf:fix>
      <sqf:fix id="get-tok-local" use-when="name() = 'TAN-R-tok'">
         <sqf:description>
            <sqf:title>Get local recommended tokenization element with this document's IRI + name
               pattern</sqf:title>
         </sqf:description>
         <sqf:add match="tan:head" position="before">
            <recommended-tokenization xmlns="tag:textalign.net,2015:ns"
               xml:id="{replace($doc-uri,'.*/([^/]+$)','$1')}">
               <IRI>
                  <xsl:value-of select="../@id"/></IRI>
               <name><xsl:value-of select="tan:name"/></name>
               <location when-accessed="{current-date()}"
                  href="{replace($doc-uri, '.*/([^/]+$)', '$1')}"/>
            </recommended-tokenization>
         </sqf:add>
      </sqf:fix>
      <sqf:fix id="get-tok-abs" use-when="name() = 'TAN-R-tok'">
         <sqf:description>
            <sqf:title>Get absolute recommended tokenization element with this document's IRI + name
               pattern</sqf:title>
         </sqf:description>
         <sqf:add match="tan:head" position="before">
            <recommended-tokenization xmlns="tag:textalign.net,2015:ns"
               xml:id="{replace($doc-uri,'.*/([^/]+$)','$1')}">
               <IRI>
                  <xsl:value-of select="../@id"/></IRI>
               <name><xsl:value-of select="tan:name"/></name>
               <location when-accessed="{current-date()}" href="{$doc-uri}"/>
            </recommended-tokenization>
         </sqf:add>
      </sqf:fix>
      <sqf:fix id="get-morph-local" use-when="name() = 'TAN-R-mor'">
         <sqf:description>
            <sqf:title>Get local morphology element with this document's IRI + name
               pattern</sqf:title>
         </sqf:description>
         <sqf:add match="tan:head" position="before">
            <morphology xmlns="tag:textalign.net,2015:ns"
               xml:id="{replace($doc-uri,'.*/([^/]+$)','$1')}">
               <IRI>
                  <xsl:value-of select="../@id"/></IRI>
               <name><xsl:value-of select="tan:name"/></name>
               <location when-accessed="{current-date()}"
                  href="{replace($doc-uri, '.*/([^/]+$)', '$1')}"/>
            </morphology>
         </sqf:add>
      </sqf:fix>
      <sqf:fix id="get-morph-abs" use-when="name() = 'TAN-R-mor'">
         <sqf:description>
            <sqf:title>Get absolute morphology element with this document's IRI + name
               pattern</sqf:title>
         </sqf:description>
         <sqf:add match="tan:head" position="before">
            <morphology xmlns="tag:textalign.net,2015:ns"
               xml:id="{replace($doc-uri,'.*/([^/]+$)','$1')}">
               <IRI>
                  <xsl:value-of select="../@id"/></IRI>
               <name><xsl:value-of select="tan:name"/></name>
               <location when-accessed="{current-date()}" href="{$doc-uri}"/>
            </morphology>
         </sqf:add>
      </sqf:fix>
   </rule>
   <rule context="text()">
      <let name="this-raw-char-seq" value="tokenize(replace(., '(.)', '$1 '), ' ')"/>
      <let name="this-nfc-char-seq"
         value="tokenize(replace(normalize-unicode(.), '(.)', '$1 '), ' ')"/>
      <let name="this-non-nfc-seq"
         value="distinct-values($this-raw-char-seq[not(. = $this-nfc-char-seq)])"/>
      <assert test=". = normalize-unicode(.)" sqf:fix="normalize-unicode">All text needs to be
         normalized (NFC). Errors: <value-of
            select="
               for $i in $this-non-nfc-seq
               return
                  concat($i, ' (U+',
                  tan:dec-to-hex(string-to-codepoints($i)), ') at ',
                  string-join(for $j in index-of($this-raw-char-seq, $i)
                  return
                     string($j), ' ')), ' '"
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
      <let name="ver" value="tokenize(., '\W+')"/>
      <report test="number($ver[1]) != $schema-version-major"
         sqf:fix="correct-major-version-only correct-whole-version">Should be schema major version
            <value-of select="$schema-version-major"/></report>
      <report test="$ver[2] and $ver[2] != $schema-version-minor"
         sqf:fix="correct-major-version-only correct-whole-version">Should be schema minor version
            <value-of select="$schema-version-minor"/></report>
      <sqf:fix id="correct-major-version-only">
         <sqf:description>
            <sqf:title>Update to major version <value-of select="$schema-version-major"
               /></sqf:title>
            <sqf:p>Choose this quick fix to replace the major version with $schema-version-major
            </sqf:p>
         </sqf:description>
         <sqf:replace match="." target="TAN-version" node-type="attribute"><value-of
               select="$schema-version-major"/></sqf:replace>
      </sqf:fix>
      <sqf:fix id="correct-whole-version">
         <sqf:description>
            <sqf:title>Update to major+minor version <value-of
                  select="concat($schema-version-major, '/')"/><value-of
                  select="$schema-version-minor"/></sqf:title>
            <sqf:p>Choose this quick fix to replace the major and minor version with
               $schema-version-major / $schema-version-minor </sqf:p>
         </sqf:description>
         <sqf:replace match="." target="TAN-version" node-type="attribute"><value-of
               select="$schema-version-major"/>/<value-of select="$schema-version-minor"
            /></sqf:replace>
      </sqf:fix>
   </rule>
   <rule context="tan:head">
      <let name="is-in-progress"
         value="
            if ($body/@in-progress = false()) then
               false()
            else
               true()"/>
      <let name="duplicate-ids" value="$all-ids[index-of($all-ids, .)[2]]"/>
      <report test="($is-in-progress = false()) and (not(tan:master-location))"
         tan:applies-to="master-location"
         sqf:fix="add-master-location-fixed add-master-location-relative">Any TAN file marked as
         being no longer in progress must have at least one master-location (after name and before
         rights-excluding-sources).</report>
      <report test="exists($duplicate-ids)" tan:applies-to="xml:id">No duplication of @xml:ids is
         permitted (<value-of
            select="
               for $i in
               $duplicate-ids
               return
                  concat($i, ' (', count(index-of($all-ids, $i)), ' times: element ',
                  string-join(distinct-values(for $j in $head//*[@xml:id = $i]
                  return
                     name($j)), ', '), ')')"
         />)</report>
      <sqf:fix id="add-master-location-fixed">
         <sqf:description>
            <sqf:title>Add master-location element after &lt;name&gt; with fixed URL</sqf:title>
            <sqf:p>Choosing this option will insert a master-location immediately after name, with
               the absolute value of the current file's URL.</sqf:p>
         </sqf:description>
         <sqf:add position="after" match="tan:name">
            <tan:master-location href="{$doc-uri}"/>
         </sqf:add>
      </sqf:fix>
      <sqf:fix id="add-master-location-relative">
         <sqf:description>
            <sqf:title>Add master-location element after &lt;name&gt; with relative URL</sqf:title>
            <sqf:p>Choosing this option will insert a master-location immediately after name, with
               the simple filename current file (i.e., no path).</sqf:p>
         </sqf:description>
         <sqf:add position="after" match="tan:name">
            <tan:master-location href="{replace($doc-uri, $doc-parent-directory, '')}"/>
         </sqf:add>
      </sqf:fix>
   </rule>
   <rule context="tan:master-location | tan:location">
      <let name="is-master-location"
         value="
            if (name() = 'master-location') then
               true()
            else
               false()"/>
      <let name="resource-type"
         value="
            if ($is-master-location) then
               'master document'
            else
               name(..)"/>
      <let name="loc-uri" value="resolve-uri(@href, $doc-uri)"/>
      <let name="loc-doc-is-available" value="doc-available($loc-uri)"/>
      <let name="loc-doc"
         value="
            if ($loc-doc-is-available) then
               doc($loc-uri)
            else
               ()"/>
      <let name="loc-ver-date-nodes" value="$loc-doc//*[(@when | @ed-when | @when-accessed)]"/>
      <let name="loc-ver-dates" value="$loc-ver-date-nodes/(@when | @ed-when | @when-accessed)"/>
      <let name="loc-ver-nos"
         value="
            for $i in $loc-ver-dates
            return
               tan:dateTime-to-decimal($i)"/>
      <let name="loc-ver-date-latest"
         value="
            if ($loc-doc-is-available and exists($loc-ver-nos)) then
               $loc-ver-dates[index-of($loc-ver-nos, max($loc-ver-nos))[1]]
            else
               ()"/>
      <let name="loc-ver-date-nodes-latest"
         value="$loc-ver-date-nodes[(@when | @ed-when | @when-accessed) = $loc-ver-date-latest]"/>
      <let name="when-accessed" value="tan:dateTime-to-decimal(@when-accessed)"/>
      <let name="is-location-of-tan-file" value="tan:must-refer-to-external-tan-file(.)"/>
      <let name="is-first-da-location"
         value="
            if ($loc-doc-is-available and
            not((preceding-sibling::tan:location, preceding-sibling::tan:master-location)[doc-available(resolve-uri(@href, $doc-uri))]))
            then
               true()
            else
               false()"/>
      <let name="is-in-progress"
         value="
            if ($loc-doc/*/(tan:body, tei:text/tei:body)/@in-progress = false()) then
               false()
            else
               true()"/>
      <let name="updates-should-be-checked"
         value="
            if (../tan:relationship = ('old version') or matches(../tan:relationship, 'edition$')) then
               true()
            else
               false()"/>
      <report role="warning" sqf:fix="replace-file"
         test="
            if (exists($loc-doc) and $is-master-location) then
               (max($loc-ver-nos) != max($doc-ver-nos))
            else
               false()"
         tan:does-not-apply-to="location"
         ><!-- If file version does not match that found in a master location, a warning will be returned -->Version
         of file does not match that of the master location (<value-of select="$doc-ver"/> versus
            <value-of select="$loc-ver-date-latest"/>)</report>
      <report test="$loc-doc-is-available = false() and not($resource-type = 'inclusion')"
         role="warning" sqf:fix="change-to-current-file-rel-uri change-to-current-file-base-uri"
         ><!-- If a file that is referenced is either unavailable or not valid XML, a warning will be returned -->The
            <value-of select="$resource-type"/> is either unavailable or is available but is not
         valid XML.</report>
      <assert
         test="
            if (exists($loc-doc) and $is-master-location) then
               deep-equal(root(.), $loc-doc)
            else
               true()"
         role="warning" tan:does-not-apply-to="location"
         ><!-- If the current file does not match one found in a master location, a warning will be returned -->The
         current document does not match the master document</assert>
      <report role="warning"
         test="
            if ($is-location-of-tan-file and $is-first-da-location)
            then
               $is-in-progress
            else
               false()"
         tan:does-not-apply-to="master-location"
         ><!-- If a referenced file is marked as being in progress, a warning will be returned -->Underlying
         TAN file is marked as being in progress (checked only against first document
         available)</report>
      <report sqf:fix="replace-with-current-date"
         test="
            if ($is-location-of-tan-file and $is-first-da-location and $updates-should-be-checked
            and exists($when-accessed))
            then
               (max($loc-ver-nos) gt $when-accessed)
            else
               false()"
         tan:does-not-apply-to="master-location" tan:applies-to="when-accessed" role="warning"
         ><!-- If a TAN file has been updated since it was last accessed, a warning will be returned -->TAN
         file updated (<value-of select="$loc-ver-date-latest"/>) since last accessed (tested only
         against first location available) <value-of
            select="
               for $i in $loc-ver-date-nodes-latest
               return
                  if (name($i) = ('comment', 'change')) then
                     concat(name($i), ': ', $i)
                  else
                     concat('edited: ', string-join(for $j in $i/ancestor-or-self::node()[name()]
                     return
                        concat(name($j), '[', string(count($j/preceding-sibling::node()[name(.) = name($j)]) + 1), ']'), '/'))"
         /></report>
      <report
         test="
            tan:must-refer-to-external-tan-file(.) and not(preceding-sibling::tan:IRI/text() and preceding-sibling::tan:name/text())
            and exists($loc-doc)"
         role="warning" sqf:fix="replace-IRI-and-name"
         ><!-- If a sibling <name> or <IRI> is missing, a warning will be returned -->IRI or name
         missing.</report>
      <sqf:fix id="change-to-current-file-rel-uri" use-when="self::tan:master-location">
         <sqf:description>
            <sqf:title>Replace with local uri</sqf:title>
            <sqf:p>Choosing this option replace the content with the current filename (without
               path)</sqf:p>
         </sqf:description>
         <sqf:replace match="@href" select="replace(base-uri(), '.*/([^/]+$)', '$1')"
            node-type="attribute" target="href"/>
      </sqf:fix>
      <sqf:fix id="change-to-current-file-base-uri" use-when="self::tan:master-location"
         tan:does-not-apply-to="location">
         <sqf:description>
            <sqf:title>Replace with base uri</sqf:title>
            <sqf:p>Choosing this option will replace the content with the absolute URL to the
               current file</sqf:p>
         </sqf:description>
         <sqf:replace match="." select="base-uri()"/>
      </sqf:fix>
      <sqf:fix id="replace-with-current-date">
         <sqf:description>
            <sqf:title>Change date to today's date</sqf:title>
            <sqf:p>Choosing this option will replace the content of @when-accessed with the current
               date</sqf:p>
         </sqf:description>
         <sqf:replace match="@when-accessed" target="when-accessed" node-type="attribute">
            <value-of select="current-date()"/>
         </sqf:replace>
      </sqf:fix>
      <sqf:fix id="replace-file" tan:does-not-apply-to="location">
         <sqf:description>
            <sqf:title>Replace current tan:head and tan:body with tan:head and tan:body from file at
               master location</sqf:title>
            <sqf:p>Choosing this option provides a radical reset of the current document, replacing
               the head and body with the head and body of the first document available</sqf:p>
         </sqf:description>
         <sqf:replace match="/*/tan:head" select="$loc-doc/*/tan:head"/>
         <sqf:replace match="/*/tan:body" select="$loc-doc/*/tan:body"/>
      </sqf:fix>
      <sqf:fix id="replace-IRI-and-name">
         <sqf:description>
            <sqf:title>Replace IRI and name with target values</sqf:title>
            <sqf:p>Choosing this option for a TAN file will replace the content of the IRI and name
               elements with the values found in the first document available.</sqf:p>
         </sqf:description>
         <sqf:replace match="preceding-sibling::tan:IRI"><xsl:element name="IRI"><xsl:value-of
                  select="$loc-doc/*/@id"/></xsl:element></sqf:replace>
         <sqf:replace match="preceding-sibling::tan:name" select="$loc-doc/*/tan:head/tan:name[1]"/>
      </sqf:fix>
   </rule>
   <rule context="tan:see-also">
      <let name="this-resolved" value="tan:resolve-include(.)"/>
      <let name="these-relationships"
         value="
            for $i in $this-resolved
            return
               normalize-space($i/tan:relationship)"/>
      <let name="must-point-to-external-tan"
         value="
            for $i in $these-relationships
            return
               if ($i = $relationship-keywords-for-tan-files) then
                  true()
               else
                  false()"/>
      <let name="first-locs"
         value="
            for $i in $this-resolved
            return
               tan:first-loc-available($i)/@href"/>
      <let name="first-docs"
         value="
            for $i in $first-locs
            return
               doc(resolve-uri($i, $doc-uri))"/>
      <let name="point-to-which-tan"
         value="
            for $i in $first-docs
            return
               name($i/*)"/>
      <report
         test="
            for $i in count($this-resolved)
            return
               $must-point-to-external-tan[$i] and not($point-to-which-tan[$i] = $all-root-names)"
         ><!-- If <relationship> keyword is $relationship-keywords-for-tan-files then parent element must point to TAN file.-->Must
         point to TAN file (checked only against first location available). <value-of
            select="
               if (exists($point-to-which-tan))
               then
                  concat('root element: ', string-join($point-to-which-tan, ', '))
               else
                  ()"
         /></report>
      <report
         test="
            for $i in count($this-resolved)
            return
               $these-relationships[$i] = $relationship-keywords-for-tan-editions and
               $point-to-which-tan[$i] ne name(/*)"
         ><!-- If <relationship> keyword is $relationship-keywords-for-tan-editions then parent element must point to a TAN file of the same type as the current file. -->The
            <value-of select="$these-relationships"/> must be the same TAN format (root element of
         target = <value-of select="$point-to-which-tan"/>).</report>
      <report
         test="
            for $i in count($this-resolved)
            return
               $these-relationships[$i] = 'dependent' and not($first-docs[$i]/*/tan:head/tan:source[tan:IRI = $doc-id])"
         >If relationship is dependent, then the current document's id must be found in at least one
         IRI in the dependent file.</report>
      <report
         test="
            for $i in count($this-resolved)
            return
               $these-relationships[$i] = $relationship-keywords-for-tan-editions and $doc-id = $first-docs[$i]/*/@id"
         ><!-- If <relationship> keyword is  $relationship-keywords-for-tan-editions then the current file and the see-also file cannot have the same @id value. -->The
            <value-of select="$these-relationships"/> cannot have the same @id value as this
         file.</report>

   </rule>
   <rule context="tan:relationship">
      <report test="@which and not(@which = $relationship-keywords-all)">Unless you define a
         relationship through an IRI + name pattern, the value must be: <value-of
            select="string-join($relationship-keywords-all, ', ')"/>
      </report>
      <assert
         test="
            if (@which) then
               @which = $relationship-keywords-all
            else
               true()"
         >@which must point to a reserved keyword (<value-of select="$relationship-keywords-all"
         />)</assert>
   </rule>
   <rule context="tan:agent">
      <let name="all-agent-uris" value="concat(' ', string-join($head/tan:agent/tan:IRI, ' '))"/>
      <let name="match" value="matches($all-agent-uris, concat(' tag:', $tan-iri-namespace))"/>
      <assert test="$match">To attach responsibility for the TAN file to a person or organization,
         at least one agent must have an IRI element that contains a tag URI whose namespace matches
         that of the URI name (<value-of select="$tan-iri-namespace"/>)</assert>
   </rule>
   <rule context="@when[parent::tan:*] | @ed-when | @when-accessed">
      <let name="this-time" value="tan:dateTime-to-decimal(.)"/>
      <report test="$this-time > $now">Future dates are not allowed (today's date and time is
            <value-of select="current-dateTime()"/>).</report>
      <assert test="(. castable as xs:dateTime) or (. castable as xs:date)"
         sqf:default-fix="current-date" sqf:fix="current-date current-date-time">Must be date or
         dateTime (@ <value-of select="name(.)"/>)</assert>
      <sqf:fix id="current-date">
         <sqf:description>
            <sqf:title>Change date to today's date</sqf:title>
            <sqf:p>If value is invalid, this quick fix will be made available, to replace the
               content of with the current date.</sqf:p>
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
      <sqf:fix id="current-date-time">
         <sqf:description>
            <sqf:title>Change date to today's date-time</sqf:title>
            <sqf:p>If value is invalid, this quick fix will be made available, to replace the
               content of with the current dateTime.</sqf:p>
         </sqf:description>
         <sqf:replace match="." target="when" node-type="attribute" use-when="name(.) = 'when'">
            <value-of select="current-dateTime()"/>
         </sqf:replace>
         <sqf:replace match="." target="ed-when" node-type="attribute"
            use-when="name(.) = 'ed-when'">
            <value-of select="current-dateTime()"/>
         </sqf:replace>
         <sqf:replace match="." target="when-accessed" node-type="attribute"
            use-when="name(.) = 'when-accessed'">
            <value-of select="current-dateTime()"/>
         </sqf:replace>
      </sqf:fix>
   </rule>
   <rule context="@to">
      <let name="when-from" value="tan:dateTime-to-decimal(../@from)"/>
      <let name="when-to" value="tan:dateTime-to-decimal(.)"/>
      <assert test="$when-to gt $when-from">Start date must precede end date.</assert>
   </rule>
   <rule
      context="@who | @ed-who | @roles | @src | @type[parent::tan:div | parent::tei:div] | @lexicon | @morphology | @reuse-type | @bitext-relation | @feature | @include">
      <let name="this-attribute-name" value="name(.)"/>
      <let name="this-attribute-value" value="."/>
      <let name="should-refer-to-which-element"
         value="$id-idrefs//tan:id[tan:idrefs/@attribute = $this-attribute-name]/@element"/>
      <let name="valid-values" value="$head//*[name(.) = $should-refer-to-which-element]/@xml:id"/>
      <let name="idrefs" value="tokenize(., '\s+')"/>
      <let name="idrefs-currently-target-what-element"
         value="
            for $n in $idrefs
            return
               name($head//*[@xml:id = $n][1])"/>
      <assert sqf:fix="get-ids add-decl-div-type"
         test="
            every $k in $idrefs-currently-target-what-element
               satisfies $k = $should-refer-to-which-element"
         id="attr-ids">@<value-of select="$this-attribute-name"/> must refer to <value-of
            select="$should-refer-to-which-element"/>s (<value-of
            select="string-join($valid-values, ', ')"/>) <value-of
            select="
               if (count($idrefs-currently-target-what-element) gt 0) then
                  concat('(currently points to ', string-join($idrefs-currently-target-what-element, ', '), ')')
               else
                  ()"
         /></assert>
      <assert test="count($idrefs) = count(distinct-values($idrefs))">Must not contain
         duplicates</assert>
      <sqf:fix id="get-ids">
         <sqf:description>
            <sqf:title>Replace content of attribute with all valid values</sqf:title>
            <sqf:p>To see a list of all possible valid values, add any invalid content, then choose
               this quick fix to replace all content with every possible value.</sqf:p>
         </sqf:description>
         <sqf:add match="." target="{name(.)}" select="string-join($valid-values, ' ')"
            node-type="attribute"/>
      </sqf:fix>
      <sqf:fix id="add-decl-div-type"
         use-when="$this-attribute-name = 'type' and $this-attribute-value = $div-type-keywords">
         <sqf:description>
            <sqf:title>Add div-type element invoking keyword</sqf:title>
            <sqf:p>If you are editing a class 1 file, and you wish to use a div type that has a TAN
               keyword and has not been invoked in the declarations, you may simply use the div type
               keyword in the context of @type, then invoke this quick fix to automatically add a
               standardized &lt;div-type> to the &lt;declarations>. </sqf:p>
         </sqf:description>
         <sqf:add match="/*/tan:head/tan:declarations/tan:div-type[1]" position="before">
            <tan:div-type xml:id="{$this-attribute-value}" which="{$this-attribute-value}"/>
         </sqf:add>
      </sqf:fix>
   </rule>
   <rule context="@regex-test | tan:pattern">
      <report test="matches(., '\\[^nrtpPsSiIcCdDwW\\|.?*+(){}#x2D#x5B#x5D#x5E\]\[\^\-]')">Every
         escape sequence must be recognized by XML schema. See
         http://www.w3.org/TR/xmlschema-2/#regexs for details.</report>
   </rule>
   <rule context="@href">
      <let name="href-resolved" value="resolve-uri(., $doc-uri)"/>
      <let name="href-is-available" value="doc-available($href-resolved)"/>
      <let name="href-doc"
         value="
            if ($href-is-available = true()) then
               doc($href-resolved)
            else
               ()"
      />
      <assert role="warning" test="$href-is-available = true()"
         ><!-- An @href will be flagged with a warning if the document is either unavailable, is not valid XML, or is at a URL trusted by a validation engine -->@href
         points to file that is either (1) not available, (2) not valid XML, or (3) at a server not
         trusted by the validation engine.</assert>
      <assert test="parent::tan:location or parent::tan:master-location" sqf:fix="get-metadata"
         sqf:default-fix="get-metadata">If not a child of tan:location or tan:master-location, then
         used only for Schematron Quick Fixes, to populate an element with &lt;IRI>, &lt;name>, and
         &lt;location> values. </assert>
      <sqf:fix id="get-metadata">
         <sqf:description>
            <sqf:title>Delete @href and insert IRI, name, and location</sqf:title>
            <sqf:p>To add the metadata of a TAN file in another one, without ever leaving the
               latter, add a valid @href value then choose this quick fix to remove the attribute
               and insert the IRI, name, and location of the file, indicating as well the date and
               time when accessed.</sqf:p>
         </sqf:description>
         <sqf:add match="..">
            <tan:IRI>
               <value-of select="$href-doc/*/@id"/></tan:IRI>
            <tan:name><value-of select="$href-doc/*/tan:head/tan:name[1]"/></tan:name>
            <tan:location when-accessed="{current-dateTime()}" href="{$href-resolved}"/>
         </sqf:add>
         <sqf:delete match="."/>
      </sqf:fix>
   </rule>
   <rule context="tan:IRI">
      <let name="count" value="count(index-of($all-iris, .))"/>
      <let name="is-iri-of-tan-file" value="tan:must-refer-to-external-tan-file(.)"/>
      <let name="first-loc" value="tan:first-loc-available(..)/@href"/>
      <let name="first-doc"
         value="
            if (exists($first-loc)) then
               doc(resolve-uri($first-loc, $doc-uri))
            else
               ()"/>
      <let name="first-da-iri-name" value="$first-doc/*/@id"/>
      <assert test="$count = 1">No duplication allowed: an IRI should appear only once in a
         file.</assert>
      <report
         test="
            if (exists($first-loc)) then
               ($is-iri-of-tan-file and not(text() = $first-da-iri-name))
            else
               false()"
         sqf:fix="replace-with-tan-id">If referring to a TAN file, the value must be a tag URN that
         matches exactly the TAN id (expected: <value-of select="$first-da-iri-name"/>)</report>
      <sqf:fix id="replace-with-tan-id">
         <sqf:description>
            <sqf:title>Replace with TAN id of 1st document available</sqf:title>
            <sqf:p>Choosing this option will replace the content of an IRI element with the value of
               the TAN id</sqf:p>
         </sqf:description>
         <sqf:stringReplace match="./text()" regex=".+">
            <value-of select="$first-da-iri-name"/>
         </sqf:stringReplace>
      </sqf:fix>
   </rule>
   <!-- Rules above relevant to inclusions dealt with here -->
   <rule context="tan:inclusion">
      <let name="first-loc-avail" value="tan:first-loc-available(.)/@href"/>
      <let name="first-doc" value="doc(resolve-uri($first-loc-avail, $doc-uri))"/>
      <let name="first-doc-resolved" value="tan:resolve-doc($first-doc)"/>
      <!-- If TAN ever permits inclusions to themselves be included, the filter below will need to change -->
      <let name="included-elements-with-ids"
         value="$first-doc-resolved//*[@xml:id][not(self::tan:inclusion)]"/>
      <!--<let name="duplicate-ids"
         value="
            for $i in $included-elements-with-ids
            return
               if ($root//*[@xml:id = $i/@xml:id and not(deep-equal(., $i))]) then
                  $i/@xml:id
               else
                  ()"/>-->
      <let name="duplicate-ids" value="$all-ids[index-of($all-ids, .)[2]]"/>
      <!-- START TESTING BLOCK -->
      <let name="test1" value="$duplicate-ids"/>
      <let name="test2" value="true()"/>
      <let name="test3" value="true()"/>
      <report test="false()">Testing. var1: <value-of select="$test1"/> var2: <value-of
            select="$test2"/> var3: <value-of select="$test3"/></report>
      <!-- END TESTING BLOCK -->
      <report test="$duplicate-ids = $included-elements-with-ids/@xml:id">No inclusion may introduce
         a duplicate @xml:id (<value-of select="$duplicate-ids"/>)</report>
      <assert test="exists($first-loc-avail)" role="fatal">Every inclusion must have at least one
         location that leads to an available document.</assert>
      <!--<report
         test="if ($first-doc/tan:body/@in-progress = false() or $first-doc/tei:text/tei:body/@in-progress = false()) 
         then false() else true()"
         role="warning">Inclusion is marked as being in progress.</report>-->
      <report test="$first-doc/*/@id = $doc-id">Inclusion has the same tag id as this
         document.</report>
   </rule>
   <rule context="*[@include]">
      <let name="self-resolved" value="tan:resolve-include(.)"/>
      <let name="self-resolved-text" value="string-join($self-resolved//text(), '')"/>
      <assert test="$self-resolved-text = normalize-unicode($self-resolved-text)">All included text
         needs to be normalized (NFC; open inclusion, validate, and resolve). </assert>
      <report test="$self-resolved//@error" role="fatal"
         ><!-- Possible validation errors: $inclusion-errors -->Inclusion error: <value-of
            select="
               for $i
               in $self-resolved//@error
               return
                  $inclusion-errors[number($i)]"
         /></report>
      <report test="text()" sqf:fix="explicate">Text is not allowed in an element with
         @include.</report>
      <sqf:fix id="explicate">
         <sqf:description>
            <sqf:title>Replace with inclusions</sqf:title>
            <sqf:p>Any element that has @include must be empty. But if you intentionally open it up
               and add text, even space characters, this quick fix will be made available upon
               validation. Choose it to comment out the original element and add after it the
               complete set of elements found in the inclusion (recursively checked against any
               inclusions in the included document). This is especially helpful for cases where you
               wish to use a TAN document as a starting point for a new file.</sqf:p>
         </sqf:description>
         <sqf:add match="." position="before">
            <xsl:comment>&lt;<xsl:value-of select="name(.)"/> include="<xsl:value-of select="@include"/>"/></xsl:comment>
         </sqf:add>
         <sqf:replace match="." select="$self-resolved"/>
      </sqf:fix>
   </rule>
   <!-- xsl:include provided below, commented out, in case validity needs to be checked; these
      fuctions are otherwise invoked through the master schematron files -->
   <!--<xsl:include href="TAN-core-functions.xsl"/>-->
</pattern>
