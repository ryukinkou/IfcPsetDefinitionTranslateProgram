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

			<!-- irregular -->
			<rdfs:Datatype rdf:about="{fcn:getFullName('currencytype')}" />

			<rdfs:Datatype rdf:about="{fcn:getFullName('values')}" />

			<xsl:call-template name="simpleTypeTranslationTemplate" />

			<xsl:call-template name="complexTypeTranslationTemplate" />

		</rdf:RDF>

	</xsl:template>

	<xsl:template name="simpleTypeTranslationTemplate">

		<xsl:for-each select="//xsd:simpleType">

			<xsl:variable name="simpleTypeName" select="./parent::*[@name]/@name" />

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

			<xsl:variable name="subject">
				<xsl:choose>
					<xsl:when test="./@name">
						<xsl:value-of select="./@name" />
					</xsl:when>
					<xsl:when test="not(./@name) and ./ancestor::*[@name]/@name">
						<xsl:value-of select="./ancestor::*[@name][1]/@name" />
					</xsl:when>
				</xsl:choose>
			</xsl:variable>

			<xsl:variable name="collectionType">
				<xsl:value-of
					select="./descendant::*[
						fcn:getQName(name())='xsd:choice' or 
						fcn:getQName(name())='xsd:sequence' or
						fcn:getQName(name())='xsd:all'][1]/name()" />
			</xsl:variable>

			<xsl:if
				test="
					./child::*[@name] or 
					(./xsd:choice | ./xsd:sequence | ./xsd:all)/child::*[@name]">

				<!-- predicate generation start -->
				<xsl:if test="./child::*[@name]">

					<xsl:call-template
						name="datatypePropertyOrObjectPropertyTranslationTemplate">
						<xsl:with-param name="objects" select="./child::*[@name]" />
					</xsl:call-template>

				</xsl:if>

				<xsl:if
					test="(./xsd:choice | ./xsd:sequence | ./xsd:all)/child::*[@name]">
					<xsl:call-template
						name="datatypePropertyOrObjectPropertyTranslationTemplate">
						<xsl:with-param name="objects"
							select="(./xsd:choice | ./xsd:sequence | ./xsd:all)/child::*[@name]" />
					</xsl:call-template>
				</xsl:if>
				<!-- predicate generation end -->

				<!-- class generation -->
				<xsl:call-template name="classTranslationTemplate">
					<xsl:with-param name="subject" select="$subject" />
					<xsl:with-param name="directProperties" select="./child::*[@name]" />
					<xsl:with-param name="collectionProperties"
						select="(./xsd:choice | ./xsd:sequence | ./xsd:all)/child::*[@name]" />
					<xsl:with-param name="collectionType" select="$collectionType" />
				</xsl:call-template>

			</xsl:if>

			<!-- 复杂类型扩展型 -->
			<xsl:if test="./xsd:complexContent">

				<xsl:call-template
					name="datatypePropertyOrObjectPropertyTranslationTemplate">
					<xsl:with-param name="objects" select="./descendant::*[@name]" />
				</xsl:call-template>

				<xsl:choose>
					<xsl:when test="$collectionType != ''">
						<xsl:call-template name="classTranslationTemplate">
							<xsl:with-param name="subject" select="$subject" />
							<xsl:with-param name="subclassOf"
								select="./descendant::xsd:extension/@base" />
							<xsl:with-param name="collectionProperties"
								select="./descendant::*[@name]" />
							<xsl:with-param name="collectionType" select="$collectionType" />
						</xsl:call-template>
					</xsl:when>
					<xsl:otherwise>
						<xsl:call-template name="classTranslationTemplate">
							<xsl:with-param name="subject" select="$subject" />
							<xsl:with-param name="subclassOf"
								select="./descendant::xsd:extension/@base" />
							<xsl:with-param name="directProperties" select="./descendant::*[@name]" />
						</xsl:call-template>
					</xsl:otherwise>
				</xsl:choose>

			</xsl:if>

			<xsl:if test="./xsd:simpleContent">

				<xsl:call-template
					name="datatypePropertyOrObjectPropertyTranslationTemplate">
					<xsl:with-param name="objects" select="./descendant::*[@name]" />
				</xsl:call-template>

				<xsl:choose>
					<xsl:when test="$collectionType != ''">
						<xsl:call-template name="classTranslationTemplate">
							<xsl:with-param name="subject" select="$subject" />
							<xsl:with-param name="collectionProperties"
								select="./descendant::*[@name]" />
							<xsl:with-param name="collectionType" select="$collectionType" />
							<xsl:with-param name="additionalProperty"
								select="./descendant::xsd:extension/@base" />
						</xsl:call-template>
					</xsl:when>
					<xsl:otherwise>
						<xsl:call-template name="classTranslationTemplate">
							<xsl:with-param name="subject" select="$subject" />
							<xsl:with-param name="directProperties" select="./descendant::*[@name]" />
							<xsl:with-param name="additionalProperty"
								select="./descendant::xsd:extension/@base" />
						</xsl:call-template>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:if>

		</xsl:for-each>

	</xsl:template>

	<xsl:template name="datatypePropertyOrObjectPropertyTranslationTemplate">
		<xsl:param name="objects" />

		<xsl:for-each select="$objects">

			<xsl:choose>

				<xsl:when test="./@type and fcn:isXsdURI(./@type)">

					<xsl:variable name="givenName">
						<xsl:choose>
							<!-- value is reserved word -->
							<xsl:when test="./@name = 'value'">
								<xsl:value-of select="'values'" />
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="./@name" />
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>

					<owl:DatatypeProperty rdf:about="{fcn:getFullName($givenName)}">
						<rdfs:range rdf:resource="{fcn:getFullName(./@type)}" />
					</owl:DatatypeProperty>
				</xsl:when>

				<xsl:otherwise>
					<xsl:choose>
						<xsl:when test="./xsd:simpleType">
							<owl:DatatypeProperty rdf:about="{fcn:getFullName('values')}" />
						</xsl:when>
						<!-- irregular branch -->
						<xsl:when test="./@name = 'currencytype'">
							<owl:DatatypeProperty rdf:about="{fcn:getFullName('values')}" />
						</xsl:when>
						<xsl:otherwise>
							<owl:ObjectProperty
								rdf:about="{fcn:getFullName(fcn:getPredicate(./@name))}">
								<rdfs:range rdf:resource="{fcn:getFullName(./@name)}" />
							</owl:ObjectProperty>
						</xsl:otherwise>
					</xsl:choose>

				</xsl:otherwise>

			</xsl:choose>

		</xsl:for-each>

	</xsl:template>

	<xsl:template name="classTranslationTemplate">
		<xsl:param name="subject" />
		<xsl:param name="subclassOf" required="no" />
		<xsl:param name="directProperties" required="no" />
		<xsl:param name="collectionProperties" required="no" />
		<xsl:param name="collectionType" required="no" />
		<xsl:param name="additionalProperty" required="no" />

		<owl:Class rdf:about="{fcn:getFullName($subject)}">

			<xsl:if test="$subclassOf">
				<rdfs:subClassOf rdf:resource="{fcn:getFullName($subclassOf)}" />
			</xsl:if>

			<!-- generate an additional property -->
			<xsl:if test="$additionalProperty">
				<rdfs:subClassOf>
					<owl:Restriction>
						<owl:onProperty rdf:resource="{fcn:getFullName('values')}" />
						<owl:allValuesFrom rdf:resource="{fcn:getFullName($additionalProperty)}" />
					</owl:Restriction>
				</rdfs:subClassOf>
			</xsl:if>

			<xsl:if test="$directProperties">
				<xsl:call-template name="propertyTranslationTemplate">
					<xsl:with-param name="properties" select="$directProperties" />
					<xsl:with-param name="isCollection" select="false()" />
				</xsl:call-template>
			</xsl:if>

			<xsl:if test="$collectionProperties">
				<xsl:choose>
					<xsl:when
						test="fcn:getQName($collectionType) = 'xsd:sequence' or 
						fcn:getQName($collectionType) = 'xsd:all'">
						<rdfs:subClassOf>
							<owl:Class>
								<owl:intersectionOf rdf:parseType="Collection">
									<xsl:call-template name="propertyTranslationTemplate">
										<xsl:with-param name="properties" select="$collectionProperties" />
										<xsl:with-param name="isCollection" select="true()" />
									</xsl:call-template>
								</owl:intersectionOf>
							</owl:Class>
						</rdfs:subClassOf>
					</xsl:when>

					<xsl:when test="fcn:getQName($collectionType) = 'xsd:choice'">
						<rdfs:subClassOf>
							<owl:Class>
								<owl:unionOf rdf:parseType="Collection">
									<xsl:call-template name="propertyTranslationTemplate">
										<xsl:with-param name="properties" select="$collectionProperties" />
										<xsl:with-param name="isCollection" select="true()" />
									</xsl:call-template>
								</owl:unionOf>
							</owl:Class>
						</rdfs:subClassOf>
					</xsl:when>
					<xsl:otherwise>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:if>

		</owl:Class>

	</xsl:template>

	<xsl:template name="propertyTranslationTemplate">
		<xsl:param name="properties" />
		<xsl:param name="isCollection" required="no" />

		<xsl:for-each select="$properties">

			<xsl:variable name="predicate">
				<xsl:choose>
					<xsl:when test="./@type and fcn:isXsdURI(./@type)">
						<xsl:choose>
							<!-- value is reserved word -->
							<xsl:when test="./@name = 'value'">
								<xsl:value-of select="'values'" />
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="./@name" />
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<xsl:otherwise>
						<xsl:choose>
							<xsl:when test="./xsd:simpleType">
								<xsl:value-of select="'values'" />
							</xsl:when>
							<!-- irregular branch -->
							<xsl:when test="./@name = 'currencytype'">
								<xsl:value-of select="'values'" />
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="fcn:getPredicate(./@name)" />
							</xsl:otherwise>
						</xsl:choose>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>

			<xsl:variable name="object">
				<xsl:choose>
					<xsl:when test="./@type and fcn:isXsdURI(./@type)">
						<xsl:value-of select="./@type" />
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="./@name" />
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>

			<xsl:choose>
				<xsl:when test="$isCollection = true()">
					<owl:Restriction>
						<owl:onProperty rdf:resource="{fcn:getFullName($predicate)}" />
						<owl:allValuesFrom rdf:resource="{fcn:getFullName($object)}" />
					</owl:Restriction>
				</xsl:when>
				<xsl:otherwise>
					<rdfs:subClassOf>
						<owl:Restriction>
							<owl:onProperty rdf:resource="{fcn:getFullName($predicate)}" />
							<owl:allValuesFrom rdf:resource="{fcn:getFullName($object)}" />
						</owl:Restriction>
					</rdfs:subClassOf>
				</xsl:otherwise>
			</xsl:choose>

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
