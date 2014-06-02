<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="2.0"
	xmlns:fcn="http://www.liujinhang.cn/paper/ifc/xsd2owl-functions.xsl"
	xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:fo="http://www.w3.org/1999/XSL/Format">

	<!-- 常量 -->
	<xsl:variable name="standardXsdPrefix" select="'xsd'" />
	<xsl:variable name="standardXsdNamespace" select="'http://www.w3.org/2001/XMLSchema'" />

	<!-- 变量引用 -->
	<xsl:variable name="fcnPredicatePrefix" select="$predicatePrefix" />
	<xsl:variable name="fcnNamespaces" select="$namespaces" />
	<xsl:variable name="fcnTargetNamespacePrefix" select="$targetNamespacePrefix" />
	<xsl:variable name="fcnLocalXsdPrefix" select="$localXsdPrefix" />
	<xsl:variable name="fcnLocalSimpleTypes" select="$localSimpleTypes" />
	<xsl:variable name="fcnLocalComplexTypes" select="$localComplexTypes" />

	<!-- 获取input的QName -->
	<xsl:function name="fcn:getQName" as="xsd:string">
		<xsl:param name="input" />
		<xsl:choose>
			<xsl:when test="contains($input,':') and not(contains($input,'#'))">
				<xsl:choose>
					<xsl:when
						test="
							$fcnNamespaces[name()=substring-before($input,':')] and 
							$fcnNamespaces[name()=substring-before($input,':')] = $standardXsdNamespace">
						<xsl:sequence
							select="concat($standardXsdPrefix,':',substring-after($input,':'))" />
					</xsl:when>
					<xsl:otherwise>
						<xsl:sequence select="$input" />
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when
				test="contains($input,'#') and $fcnNamespaces[.=substring-before($input,'#')]">
				<xsl:sequence
					select="concat($fcnNamespaces[.=substring-before($input,'#')]/name(),':',substring-after($input,'#'))" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:sequence select="concat($fcnTargetNamespacePrefix,':',$input)" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<!-- 获得谓词 -->
	<xsl:function name="fcn:getPredicate" as="xsd:string">
		<xsl:param name="input" />
		<xsl:choose>
			<xsl:when test="$input = ''">
				<xsl:sequence select="$input" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="localName" select="fcn:getLocalName($input)" />
				<xsl:variable name="nameHeader" select="substring($localName,1,1)" />
				<xsl:variable name="nameTail" select="substring($localName,2)" />
				<xsl:sequence
					select="concat($fcnPredicatePrefix,upper-case($nameHeader),$nameTail)" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<!-- 获取input的全名 -->
	<xsl:function name="fcn:getFullName" as="xsd:string">
		<xsl:param name="input" />
		<xsl:variable name="QName" select="fcn:getQName($input)" />
		<xsl:choose>
			<xsl:when test="substring-before($QName,':') = $standardXsdPrefix">
				<xsl:sequence
					select="concat($standardXsdNamespace,'#',substring-after($QName,':'))" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:sequence
					select="concat($fcnNamespaces[name()=substring-before($QName,':')],'#',substring-after($QName,':'))" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<!-- 获取input的本地名称 -->
	<xsl:function name="fcn:getLocalName" as="xsd:string">
		<xsl:param name="input" />
		<xsl:variable name="QName" select="fcn:getQName($input)" />
		<xsl:sequence select="substring-after($QName,':')" />
	</xsl:function>

	<!-- 获取input的命名空间URI -->
	<xsl:function name="fcn:getNamespaceURI" as="xsd:string">
		<xsl:param name="input" />
		<xsl:variable name="fullName" select="fcn:getFullName($input)" />
		<xsl:sequence select="substring-before($fullName,'#')" />
	</xsl:function>

	<!-- 获取input的命名空间前缀 -->
	<xsl:function name="fcn:getNamespacePrefix" as="xsd:string">
		<xsl:param name="input" />
		<xsl:variable name="QName" select="fcn:getQName($input)" />
		<xsl:sequence select="substring-before($QName,':')" />
	</xsl:function>

	<!-- 在上下文的子节点里面寻找名称为name的元素，存在返回true，不存在返回false -->
	<xsl:function name="fcn:containsElement" as="xsd:boolean">
		<!-- 上下文 -->
		<xsl:param name="context" />
		<!-- 元素/属性的名称 -->
		<xsl:param name="name" as="xsd:string" />
		<xsl:sequence select="count($context/xsd:element[@name=$name])>0" />
	</xsl:function>

	<!-- 在上下文的子节点里面寻找名称为name的属性，存在返回true，不存在返回false -->
	<xsl:function name="fcn:containsAttribute" as="xsd:boolean">
		<!-- 上下文 -->
		<xsl:param name="context" />
		<!-- 元素/属性的名称 -->
		<xsl:param name="name" as="xsd:string" />
		<xsl:sequence select="count($context/xsd:attribute[@name=$name])>0" />
	</xsl:function>

	<!-- 在上下文的子节点里面寻找名称为name的元素/属性，存在返回true，不存在返回false -->
	<xsl:function name="fcn:containsElementOrAttribute" as="xsd:boolean">
		<!-- 上下文 -->
		<xsl:param name="context" />
		<!-- 元素/属性的名称 -->
		<xsl:param name="name" as="xsd:string" />
		<xsl:sequence
			select="fcn:containsElement($context,$name) or fcn:containsAttribute($context,$name)" />
	</xsl:function>

	<!-- 检查该input是否属于XMLSchema命名空间 -->
	<xsl:function name="fcn:isXsdURI" as="xsd:boolean">
		<xsl:param name="input" as="xsd:string" />
		<xsl:variable name="QName" select="fcn:getQName($input)" />
		<xsl:sequence select="substring-before($QName,':') = $standardXsdPrefix" />
	</xsl:function>

	<!-- 检查该input是不是一个Datatype定义 -->
	<xsl:function name="fcn:isDatatypeDefinition" as="xsd:boolean">
		<xsl:param name="input" as="xsd:string" />
		<xsl:choose>
			<xsl:when
				test="
				fcn:isXsdURI($input) or
				($fcnLocalSimpleTypes[@name=fcn:getLocalName($input)]/xsd:restriction/@base and
				count($fcnLocalSimpleTypes[@name=fcn:getLocalName($input)]/xsd:restriction/xsd:enumeration) = 0 )">
				<xsl:sequence select="true()" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:sequence select="false()" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<!-- 检查该input是不是一个枚举型class定义 -->
	<xsl:function name="fcn:isEnumClassDefinition" as="xsd:boolean">
		<xsl:param name="input" as="xsd:string" />
		<xsl:choose>
			<xsl:when
				test="
				$fcnLocalSimpleTypes[@name=fcn:getLocalName($input)]/xsd:restriction/@base and
				count($fcnLocalSimpleTypes[@name=fcn:getLocalName($input)]/xsd:restriction/xsd:enumeration) > 0">
				<xsl:sequence select="true()" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:sequence select="false()" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<!-- 检查该input是不是一个class定义 -->
	<xsl:function name="fcn:isClassDefinition" as="xsd:boolean">
		<xsl:param name="input" as="xsd:string" />
		<xsl:choose>
			<xsl:when test="$fcnLocalComplexTypes[@name=fcn:getLocalName($input)]">
				<xsl:sequence select="true()" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:sequence select="false()" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<!-- 检查元素的名称是否存在于被忽略列表中 -->
	<xsl:function name="fcn:isIgnoredByNameList" as="xsd:boolean">
		<xsl:param name="name" />
		<xsl:sequence
			select="sum(for $ignoreName in $ignoreNameList return (($ignoreName = $name) cast as xsd:integer)) != 0" />
	</xsl:function>

	<!-- 检查元素的名称是否属于被忽略的模式 -->
	<xsl:function name="fcn:isNameIgnoredByPattern" as="xsd:boolean">
		<xsl:param name="name" />
		<xsl:sequence
			select="sum(for $ignoreNamePattern in $ignoreNamePatternList return (contains($name,$ignoreNamePattern) cast as xsd:integer)) != 0" />
	</xsl:function>

	<!-- 检查元素的名称是否属于需要被忽略 -->
	<xsl:function name="fcn:isNameIgnored" as="xsd:boolean">
		<xsl:param name="name" />
		<xsl:sequence
			select="fcn:isIgnoredByNameList($name) or fcn:isNameIgnoredByPattern($name)" />
	</xsl:function>

	<!-- 获取minOccurs -->
	<xsl:function name="fcn:getMinOccurs">
		<xsl:param name="minOccurs" />
		<xsl:param name="use" required="no" />
		<xsl:param name="nillable" required="no" />
		<xsl:choose>
			<xsl:when test="$minOccurs">
				<xsl:sequence select="$minOccurs" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:choose>
					<xsl:when test="$use='required'">
						<xsl:sequence select="1" />
					</xsl:when>
					<xsl:when test="$use='optional' or $nillable='true'">
						<xsl:sequence select="0" />
					</xsl:when>
					<xsl:otherwise>
						<xsl:sequence select="0" />
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<!-- 获取maxOccurs -->
	<xsl:function name="fcn:getMaxOccurs">
		<xsl:param name="maxOccurs" required="no" />
		<xsl:choose>
			<xsl:when test="$maxOccurs">
				<xsl:value-of select="$maxOccurs" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="'unbounded'" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<!-- 名字发生器 -->
	<xsl:function name="fcn:generateName">
		<xsl:param name="array" />
		<xsl:variable name="length" select="count($array)" />
		<xsl:choose>
			<xsl:when test="$length = 1">
				<xsl:sequence select="$array[1]" />
			</xsl:when>
			<xsl:when test="$length > 1">
				<xsl:sequence select="concat($array[$length - 1],'_',$array[$length])" />
			</xsl:when>
		</xsl:choose>
	</xsl:function>

</xsl:stylesheet>
