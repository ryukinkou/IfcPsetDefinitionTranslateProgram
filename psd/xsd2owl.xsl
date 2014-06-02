<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="2.0"
	xmlns:fcn="http://www.liujinhang.cn/paper/ifc/xsd2owl-functions.xsl"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xsd="http://www.w3.org/2001/XMLSchema"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:xlink="http://www.w3.org/1999/xlink#" xmlns:owl="http://www.w3.org/2002/07/owl#">

	<!-- function文件引用 -->
	<xsl:import href="xsd2owl-functions.xsl" />

	<!-- 文档输出定义 -->
	<xsl:output media-type="text/xml" version="1.0" encoding="UTF-8"
		indent="yes" use-character-maps="owl" />
	<xsl:strip-space elements="*" />
	<xsl:character-map name="owl">
		<xsl:output-character character="&amp;" string="&amp;" />
	</xsl:character-map>

	<!-- 动词前缀 -->
	<xsl:variable name="predicatePrefix" select="'has'" />

	<!-- 目标命名空间 -->
	<xsl:variable name="targetNamespace">
		<xsl:value-of select="/xsd:schema/@targetNamespace" />
	</xsl:variable>

	<!-- 目标命名空间前缀 -->
	<xsl:variable name="targetNamespacePrefix">
		<xsl:for-each select="/xsd:schema/namespace::*">
			<xsl:if test=". = $targetNamespace">
				<xsl:value-of select="name()" />
			</xsl:if>
		</xsl:for-each>
	</xsl:variable>

	<!-- 忽略列表 -->
	<xsl:variable name="ignoreNameList"
		select="'ifcXML','uos','Seq-anyURI','instanceAttributes','pos','arraySize','itemType','cType',nil" />

	<!-- 忽略模式列表 -->
	<xsl:variable name="ignoreNamePatternList" select="'-wrapper',nil" />

	<!-- 本地定义的SimpleType -->
	<xsl:variable name="localSimpleTypes" select="/xsd:schema/xsd:simpleType" />

	<!-- 本地定义的ComplexType -->
	<xsl:variable name="localComplexTypes" select="/xsd:schema/xsd:complexType" />

	<!-- Xsd的本地前缀 -->
	<xsl:variable name="localXsdPrefix">
		<xsl:for-each select="/xsd:schema/namespace::*">
			<xsl:if test=". = 'http://www.w3.org/2001/XMLSchema'">
				<xsl:value-of select="name()" />
			</xsl:if>
		</xsl:for-each>
	</xsl:variable>

	<!-- 命名空间 -->
	<xsl:variable name="namespaces" select="/xsd:schema/namespace::*" />

	<!-- 本地定义的命名空间 -->
	<xsl:variable name="localNamespaces"
		select="namespaces[
			not(name() = '' or 
				name() = 'xsd' or 
				name() = 'xml' or 
				name() = 'xlink' or
				name() = $localXsdPrefix)]" />

	<!-- name|type,node 图 -->
	<xsl:key name="propertyMap"
		match="
		//xsd:element[
			@name 
			and (ancestor::xsd:complexType or ancestor::xsd:group)
			and not(fcn:containsElementOrAttribute(/xsd:schema, @name))
		] |
		//xsd:attribute[
			@name 
			and (ancestor::xsd:complexType or ancestor::xsd:attributeGroup)
			and not(fcn:containsElementOrAttribute(/xsd:schema, @name))
		]"
		use="concat(@name,'|',@type)" />

	<!-- schema的匹配模板 -->
	<xsl:template match="/xsd:schema">

		<!-- DTD START -->
		<!-- 输出 '<!DOCTYPE rdf:RDF [' -->
		<xsl:text disable-output-escaping="yes">&#10;&lt;!DOCTYPE rdf:RDF [&#10;</xsl:text>
		<!-- 输出常用的命名空间DTD -->
		<xsl:text disable-output-escaping="yes">&#09;&lt;!ENTITY xsd 'http://www.w3.org/2001/XMLSchema#' &gt;&#10;</xsl:text>
		<xsl:text disable-output-escaping="yes">&#09;&lt;!ENTITY xml 'http://www.w3.org/XML/1998/namespace#' &gt;&#10;</xsl:text>
		<xsl:text disable-output-escaping="yes">&#09;&lt;!ENTITY xlink 'http://www.w3.org/1999/xlink#' &gt;&#10;</xsl:text>
		<xsl:text disable-output-escaping="yes">&#09;&lt;!ENTITY owl 'http://www.w3.org/2002/07/owl#' &gt;&#10;</xsl:text>
		<xsl:text disable-output-escaping="yes">&#09;&lt;!ENTITY rdfs 'http://www.w3.org/2000/01/rdf-schema#' &gt;&#10;</xsl:text>
		<xsl:text disable-output-escaping="yes">&#09;&lt;!ENTITY rdf 'http://www.w3.org/1999/02/22-rdf-syntax-ns#' &gt;&#10;</xsl:text>

		<!-- 输出本地命名空间的DTD -->
		<xsl:for-each select="$localNamespaces">
			<!-- 输出 <!ENTITY name() . > -->
			<xsl:text disable-output-escaping="yes">&#09;&lt;!ENTITY
			</xsl:text>
			<xsl:value-of select="name()" />
			<xsl:text disable-output-escaping="yes"> '</xsl:text>
			<xsl:choose>
				<!-- 输出targetNamespace的时候，使用'#'符号代替命名空间 -->
				<xsl:when test=". = $targetNamespace">
					<xsl:text disable-output-escaping="yes">#</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<!-- 输出命名空间，并且自动补全'#'符号 -->
					<xsl:value-of select="." />
					<xsl:if test="not(contains(.,'#'))">
						<xsl:text disable-output-escaping="yes">#</xsl:text>
					</xsl:if>
				</xsl:otherwise>
			</xsl:choose>
			<!-- 输出 '> -->
			<xsl:text disable-output-escaping="yes">' &gt;&#10;</xsl:text>
		</xsl:for-each>

		<!-- 输出 ]> -->
		<xsl:text disable-output-escaping="yes">]&gt;&#10;</xsl:text>
		<!-- DTD END -->

		<rdf:RDF xml:base="{$targetNamespace}">

			<!-- 输出本地Namespace，命名空间暂时定义为'&name();' -->
			<xsl:variable name="localNamespacesTemp">
				<xsl:for-each select="$localNamespaces">
					<xsl:element name="{name()}:x" namespace="&#38;{name()};" />
				</xsl:for-each>
			</xsl:variable>
			<xsl:copy-of select="$localNamespacesTemp/*/namespace::*" />
			<xsl:variable name="baseNamespacesTemp">
				<xsl:element name="{'base'}:x" namespace="{$targetNamespace}" />
			</xsl:variable>
			<xsl:copy-of select="$baseNamespacesTemp/*/namespace::*" />

			<!-- 本体的顶级信息定义 -->
			<owl:Ontology rdf:about="{$targetNamespace}">
				<rdfs:comment>IFC</rdfs:comment>
			</owl:Ontology>

			<owl:ObjectProperty rdf:ID="any" />

			<xsl:call-template name="property" />

			<xsl:call-template name="simpleTypeTranslationTemplate" />

			<xsl:call-template name="complexTypeTranslationTemplate" />

		</rdf:RDF>

	</xsl:template>

	<xsl:template name="property">

		<xsl:for-each
			select=" 
				//xsd:element [ @name and (ancestor::xsd:complexType or ancestor::xsd:group) 
				and generate-id()=generate-id(key('propertyMap',concat(@name,'|',@type))[1])
				and fcn:isNameIgnored(@name) = false() ] |
				//xsd:attribute [ @name and (ancestor::xsd:complexType or ancestor::xsd:attributeGroup)
				and generate-id()=generate-id(key('propertyMap',concat(@name,'|',@type))[1])
				and fcn:isNameIgnored(@name) = false() ] ">

			<xsl:variable name="currentName" select="./@name" />
			<xsl:variable name="currentType" select="./@type" />

			<xsl:choose>
				<xsl:when test="$currentType and fcn:isXsdURI($currentType)">

					<owl:DatatypeProperty rdf:about="{fcn:getFullName($currentName)}">
						<rdfs:range rdf:resource="{fcn:getFullName($currentType)}" />
					</owl:DatatypeProperty>

				</xsl:when>
				<xsl:otherwise>

					<owl:ObjectProperty
						rdf:about="{fcn:getFullName(fcn:getPredicate($currentName))}">
					</owl:ObjectProperty>

				</xsl:otherwise>
			</xsl:choose>

		</xsl:for-each>
	</xsl:template>

	<xsl:template name="simpleTypeTranslationTemplate">

		<xsl:for-each select="//xsd:simpleType">

			<xsl:variable name="simpleTypeName"
				select="fcn:generateName(./ancestor::*[@name]/@name)" />

			<xsl:variable name="enumArray" as="element()*"
				select="./descendant::xsd:enumeration" />

			<xsl:choose>
				<xsl:when test="count($enumArray) > 1">
					<rdfs:Datatype rdf:about="{fcn:getFullName($simpleTypeName)}">
						<owl:equivalentClass>
							<rdfs:Datatype>
								<owl:oneOf>
									<xsl:call-template name="enumEndlessLoop">
										<xsl:with-param name="pos" select="1" />
										<xsl:with-param name="array" select="$enumArray" />
									</xsl:call-template>
								</owl:oneOf>
							</rdfs:Datatype>
						</owl:equivalentClass>
					</rdfs:Datatype>
				</xsl:when>
			</xsl:choose>

		</xsl:for-each>

	</xsl:template>

	<xsl:template name="complexTypeTranslationTemplate">




		<xsl:for-each select="//xsd:complexType">

			<xsl:message select="'------'" />
			<xsl:variable name="master">
				<xsl:choose>
					<xsl:when test="./@name">
						<xsl:value-of select="./@name" />
					</xsl:when>
					<xsl:when test="not(./@name) and ./ancestor::*[@name]/@name">
						<xsl:value-of select="./ancestor::*[@name][1]/@name" />
					</xsl:when>
				</xsl:choose>
			</xsl:variable>
			
			<xsl:message> master : <xsl:value-of select="$master" /></xsl:message>

			<xsl:for-each select="fcn:findNamedChildren(.)">

				<xsl:message> slave : <xsl:value-of select="./@name" /> | <xsl:value-of select="./@type" /></xsl:message>

			</xsl:for-each>







		</xsl:for-each>

	</xsl:template>





	<xsl:template name="enumEndlessLoop">
		<xsl:param name="pos" />
		<xsl:param name="array" />

		<rdf:Description>
			<rdf:first>
				<xsl:value-of select="$array[$pos]/@value" />
			</rdf:first>

			<xsl:choose>
				<xsl:when test="count($array) >= $pos">
					<rdf:rest>
						<xsl:call-template name="enumEndlessLoop">
							<xsl:with-param name="pos" select="$pos + 1" />
							<xsl:with-param name="array" select="$array" />
						</xsl:call-template>
					</rdf:rest>
				</xsl:when>
				<xsl:otherwise>
					<rdf:rest rdf:resource="&amp;rdf;nil" />
				</xsl:otherwise>
			</xsl:choose>

		</rdf:Description>

	</xsl:template>

</xsl:stylesheet>
