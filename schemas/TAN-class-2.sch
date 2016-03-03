<?xml version="1.0" encoding="UTF-8"?>
<!-- To do: 
   Change default behavior for tokenization: if tokenization on a language of a source 
   is not specified then adopt the first recommended tokenization specified in the source.
   If for some reason the source has neglected this, then adopt general-words-only as a
   default.
   ADD rule to <tokenization>: for any tokenization not already recommended by 
   a source, ensure that tokenization on the source text is identical no matter how 
   modifying letters are handled (probably time consuming)
   Ensure that <rename-div-ns> does not break the LDUR; document for guidelines
   Ensure that tan:tok/@cont is used to fuse tokens.
-->

<pattern xmlns="http://purl.oclc.org/dsdl/schematron" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
   <title>Schematron tests for class 2 TAN files.</title>

   <rule context="tan:source">
      <let name="self-resolved" value="tan:resolve-include(.)"/>
      <let name="this-pos"
         value="
            if (@include) then
               $src-count
            else
               count(preceding-sibling::tan:source) + 1"
      />
      <let name="these-prepped-data" value="$src-1st-da-data-prepped[position() = $this-pos]"/>
      <let name="exists-new-version"
         value="$src-1st-da-heads[position() = $this-pos]/tan:see-also[tan:relationship = 'new version']"/>
      <let name="duplicate-leafdiv-flatrefs"
         value="for $i in $these-prepped-data return $i/tan:div[text()]/@ref[index-of($i/tan:div[text()]/@ref,.)[2]]"/>
      <assert
         test="every $i in $self-resolved
               satisfies exists(tan:first-loc-available($i))"
         role="fatal">At least one copy of each source must be available to validate file.</assert>
      <report test="exists($duplicate-leafdiv-flatrefs)">
         After declarations are applied, source must
         preserve the Leaf Div Uniqueness Rule (broken at <value-of
            select="string-join($duplicate-leafdiv-flatrefs, ', ')"/>).</report>
      <report test="$exists-new-version" role="warning" sqf:fix="use-new-edition"><!-- Upon validation, if a source is found to have a <see-also> that has a <relationship> of 'new-version', a warning will be returned indicating that an updated version is available -->New version
         exists. IRI: <value-of select="$exists-new-version/tan:IRI"/> Name: <value-of
            select="$exists-new-version/tan:name"/>
         <value-of select="$exists-new-version/tan:desc"/> Location: <value-of
            select="$exists-new-version/tan:location/@href"/></report>
      <sqf:fix id="use-new-edition">
         <sqf:description>
            <sqf:title>Replace with new version</sqf:title>
            <sqf:p>If the source is found to have a see-also that has a relationship of 'new-version', choosing this option will replace the IRI + name pattern with the one in the source file's see-also.</sqf:p>
         </sqf:description>
         <sqf:delete match="child::*"/>
         <sqf:add match="."
            select="$exists-new-version/* except $exists-new-version/tan:relationship"/>
      </sqf:fix>
   </rule>
   <rule context="tan:suppress-div-types|tan:div-type-ref|tan:rename-div-ns">
      <let name="this-src-list" value="tan:src-ids-to-nos(@src)"/>
      <let name="this-div-types" value="tokenize(@div-type-ref,'\s+')"/>
      <let name="src-div-type-mismatch"
         value="
            for $i in $this-src-list,
               $j in $this-div-types
            return
               if ($src-1st-da-heads[$i]/tan:declarations/tan:div-type[@xml:id = $j])
               then
                  ()
               else
                  concat($src-ids[$i], ':', $j)"
      />
      <report test="count($src-div-type-mismatch) gt 0">Every div type value must be valid in every source (
         <value-of select="$src-div-type-mismatch"/>).</report>
      
   </rule>
   <rule context="tan:rename">
      <let name="this-src-list" value="tan:src-ids-to-nos(../@src)"/>
      <let name="this-div-type-list" value="tokenize(../@div-type-ref,'\s+')"/>
      <!--<let name="this-div-type-list-orig"
         value="for $i in $this-src-list return string-join(for $j in $this-div-type-list return 
         ($head/tan:declarations/tan:rename-div-types[tan:src-ids-to-nos(@src) = $i]/tan:rename[@new = $j]/@old,$j)[1],' ')"/>-->
      <!--<let name="this-div-type-list-orig-as-regex"
         value="for $i in $this-div-type-list-orig return concat('(',replace($i,' ','|'),')')"/>-->
      <let name="this-div-n" value="@old"/>
      <let name="this-div-type-ord-check"
         value="$div-type-ord-check/tan:source[position() = $this-src-list]/tan:div-type[@id = $this-div-type-list]"/>
      <let name="ns-are-type-i"
         value="every $i in $this-div-type-ord-check satisfies $i/@type = 'i'"/>
      <let name="ns-are-type-a"
         value="every $i in $this-div-type-ord-check satisfies $i/@type = 'a'"/>
      <let name="ns-are-what-type"
         value="for $i in $this-div-type-ord-check/@type return $n-type-label[index-of($n-type,$i)]"/>
      <assert
         test="
            if (matches($this-div-n, '#')) then
               true()
            else
               every $i in $this-src-list
                  satisfies
                  some $j in $src-1st-da-data-prepped[$i]/tan:div[tokenize(@n, $separator-hierarchy-regex) = $this-div-n]
                     satisfies tokenize($j/@type, $separator-hierarchy-regex) = $this-div-type-list"
         >For rename-div-ns, every n value must be found in at least one div type in every
         source.</assert>
      <assert test="matches(@old,'#') = matches(@new,'#')">For rename-div-ns, if a numeration system
         is to be renamed, the appropriate rename element must have the valid pattern identifiers in @old and @new for letter, Roman, or Arabic numerals -- #a, #i, or #1 respectively</assert>
      <report test="@old = @new">@old and @new may not take the same value</report>
      <assert test="if (@old = '#a') then ($ns-are-type-a) else true()">
         <value-of select="$source-lacks-id"/>If converting @n numeration
         from letter numerals to Arabic, the @n values for each div type of each source must be
         predominantly letter numerals (currently <value-of
            select="string-join($ns-are-what-type,', ')"/>)</assert>
      <assert test="if (@old = '#i') then ($ns-are-type-a) else true()">If converting @n numeration
         from roman numerals to Arabic, the @n values for each div type of each source must be
         predominantly Roman numerals (currently <value-of
            select="string-join($ns-are-what-type,', ')"/>)</assert>
   </rule>
   <rule context="@ref">
      <let name="these-refs" value="normalize-space(.)"/>
      <let name="help-requested" value="tan:help-requested(..)"/>
      <let name="this-src-list" value="if (../@src) then tan:src-ids-to-nos(../@src) else 1"/>
      <let name="this-refs-norm"
         value="
            for $i in $this-src-list
            return
               tan:normalize-refs(.)"
      />
      <let name="possible-divs" value="for $i in $this-src-list, $j in $this-refs-norm, $k in tokenize($j,' [-,] ')
          return $src-1st-da-data-prepped[$i]/tan:div[matches(@ref,tan:escape($j))]"/>
      <let name="possible-refs" value="$possible-divs/@ref"/>
      <let name="ref-range-must-join-siblings"
         value="if (../parent::tan:realign or ../..[@distribute] or ../..[@xml:id]) then true() else false()"/>
      <report
         test="$ref-range-must-join-siblings and (some $i in tan:ref-range-check(.) satisfies $i = false())"
         >In any @ref whose values might be distributed, every range (references joined by a hyphen)
         must begin and end with siblings.</report>
      <report test="$help-requested" role="info"><!-- If you add a question mark to a partially completed reference, you will get in response a list of all possible valid references -->Help: <value-of select="$possible-refs"/></report>
   </rule>
   <rule context="tan:tok">
      <let name="src-data-for-this-tok" value="tan:pick-tokenized-prepped-class-1-data(.)//tan:body"/>
      <let name="help-requested" value="tan:help-requested(.)"/>
      <let name="val-without-help" value="normalize-space(replace(@val,'\s+\?|\?\s+',''))"/>
      <let name="token-numbers"
         value="
            for $i in $src-data-for-this-tok/tan:div/tan:tok[last()]/@n
            return
               tan:sequence-expand(@pos, $i)"
      />
      <let name="token-ceiling"
         value="min($src-data-for-this-tok/tan:div/tan:tok[last()]/@n)"/>
      <let name="char-ceiling"
         value="min(for $i in $src-data-for-this-tok//tan:tok return string-length($i))"/>
      <let name="this-chars"
         value="if (@chars) then normalize-space(replace(@chars,'\?','')) else ()"/>
      <let name="this-char-max"
         value="if (exists($this-chars)) then tan:max-integer($this-chars) else 1"/>
      <let name="this-char-min-last"
         value="if (exists($this-chars) and exists($char-ceiling)) then tan:min-last($this-chars,$char-ceiling) else 1"/>
      <let name="src-data-for-sibling-toks"
         value="for $i in (preceding-sibling::tan:tok, following-sibling::tan:tok)[not(tan:help-requested(.))] 
         return tan:pick-tokenized-prepped-class-1-data($i)"/>
      <let name="duplicate-tokens"
         value="for $i in $src-data-for-this-tok//tan:tok, 
         $j in $src-data-for-sibling-toks//tan:tok return
         if (deep-equal($i,$j)) then 
         if ($i/../@ref = $j/../@ref and $i/../../@id = $j/../../@id) then true() else () 
         else ()"/>
      <report test="exists($duplicate-tokens) and not($help-requested)">May not point to the same
         token that a sibling tok element does.</report>
      <report test="some $i in $src-data-for-this-tok/tan:div satisfies $i = $tokenization-errors"
         tan:does-not-apply-to="tok">Tokenization error (<value-of
            select="for $i in $src-data-for-this-tok/tan:div[. = $tokenization-errors] return concat($i/@ref,': ',$i/@lang)"
         />)</report>
      <report test="not(@pos or @val)">Must point to a string value via @val, a sequence via @pos, or
         both.</report>
      <report test="$src-data-for-this-tok/tan:div/@error">Every value of @ref must be found in
         every source (<value-of
            select="for $i in $src-data-for-this-tok/tan:div[@error] return concat($i/../@id,': ',$i/@ref)"
         />).</report>
      <report test="$src-data-for-this-tok/tan:div/tan:tok[@error]">Every token picked must appear
         in every ref in every source<value-of
            select="if (tokenize(@val,'\s+') = 'last') then ' (&quot;last&quot; 
            usually goes with the attribute @pos, not @val)' else ()"
         /> (errors: <value-of
            select="for $i in $src-data-for-this-tok/tan:div[tan:tok[@error]] return 
            concat($i/../@id,': ',$i/@ref,' tok ',string-join($i/tan:tok/@error,' '))"
         />) <value-of select="$src-data-for-this-tok//(@error, @test)"/></report>
      <report
         test="if (exists($this-chars)) then ($this-char-max gt $char-ceiling) or ($this-char-min-last lt 1) 
         else false()" tan:applies-to="char"
         >If @chars is used, every character must appear in every token in every ref in every source (tokens
         chosen have <value-of select="$char-ceiling"/> characters max)</report>
      <report test="$src-data-for-this-tok/tan:div[not(tan:tok)]">@ref must refer to a leaf div in
         every source (<value-of
            select="string-join(for $i in $src-data-for-this-tok/tan:div[not(tan:tok)] return concat($i/../@id,':',$i/@ref),', ')"
         />)</report>
      <report test="matches(@pos,'\?')" role="info" tan:applies-to="ord">
         <!-- If you insert a question mark anywhere as the value of @pos and then validate the file, you will be given a list of allowed values. -->
         Help: acceptable values 1 through <value-of
            select="$token-ceiling"/></report>
      <report test="matches(@chars,'\?')" role="info" tan:applies-to="chars">
         <!-- If you insert a question mark anywhere as the value of @chars and then validate the file, you will be given a list of allowed values. -->
         Help: acceptable values 1 through <value-of
            select="$char-ceiling"/></report>
      <report
         test="
            @chars and (some $i in $src-data-for-this-tok/tan:div/tan:tok
               satisfies matches($i, '\p{M}'))"
         tan:applies-to="chars" role="warning">Any @chars applied to a token that has combining
         characters will identify only base characters, grouped with any immediately following
         combining characters.</report>
      <report
         test="$token-numbers = 1 and parent::tan:split-leaf-div-at and
            not($help-requested)"
         >May not be used to split a leaf div at the first token.</report>
      <report test="@val and $help-requested" role="info" tan:applies-to="val">
         <!-- If you insert a question mark anywhere as the value of @val and then validate the file, you will be given a list of allowed values. -->
         Help: 
         <value-of
            select="for $i in $src-data-for-this-tok,
                  $j in $i/tan:div
               return
                  string-join(concat($j/@ref, ': ', string-join(for $k in distinct-values($j/tan:tok)
                  return
                     concat($k, '[', count($j/tan:tok[. = $k]), ']'), ', ')), '; ')"
         /></report>
      <report test="@cont and count($src-data-for-this-tok//tan:tok) gt 1">Any &lt;tok>
      that is continued via @cont must point to only a single token.</report>
      <report
         test="preceding-sibling::tan:tok[1]/@cont and count($src-data-for-this-tok//tan:tok) gt 1"
         >Any &lt;tok> that continues a previous one (via @cont) must point to only a single
         token.</report>
      <report test="@cont and not(following-sibling::tan:tok)" tan:applies-to="cont">Any &lt;tok> taking 
         @cont must be followed by at least one other &lt;tok>.</report>
   </rule>
   <rule context="@strength|@conf">
      <let name="pos" value="count(../preceding-sibling::*[not(@cont)])"/>
      <let name="joined-siblings" value="../../(tan:div-ref,tan:tok)[count(preceding-sibling::*[not(@cont)]) = $pos]"/>
      <report test="count($joined-siblings//(@strength | @conf)) gt 1">Neither @strength nor @conf
         may be repeated by siblings joined by @cont.</report>
   </rule>
   <rule context="@src">
      <let name="these-srcs" value="tokenize(replace(.,$help-trigger-regex,' '),'\s+')"/>
      <let name="this-src-list" value="tan:src-ids-to-nos($these-srcs)"/>
      <report test="count($these-srcs) != count($this-src-list)">Not a complete match</report>
   </rule>
</pattern>
