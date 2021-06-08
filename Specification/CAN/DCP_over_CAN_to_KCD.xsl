<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:acosar="http" exclude-result-prefixes="xs"
    version="2.0">

    <xsl:function name="acosar:int-to-hex-rec" as="xs:string">
        <xsl:param name="in" as="xs:integer"/>
        <xsl:sequence
            select="
                if ($in eq 0)
                then
                    '0'
                else
                    concat(if ($in gt 16)
                    then
                        acosar:int-to-hex-rec($in idiv 16)
                    else
                        '',
                    substring('0123456789ABCDEF',
                    ($in mod 16) + 1, 1))"
        />
    </xsl:function>

    <xsl:function name="acosar:data_type_to_length" as="xs:string">
        <xsl:param name="data_type" as="xs:string"/>
        <xsl:sequence
            select="
                if (ends-with($data_type, '8'))
                then
                    '8'
                else
                    if (ends-with($data_type, '8'))
                    then
                        '8'
                    else
                        ''
                "/>
        <xsl:if test="ends-with($data_type, '8')">
            <xsl:attribute name="length">8</xsl:attribute>
        </xsl:if>
        <xsl:if test="ends-with($data_type, '16')">
            <xsl:attribute name="length">16</xsl:attribute>
        </xsl:if>
        <xsl:if test="ends-with($data_type, '32')">
            <xsl:attribute name="length">32</xsl:attribute>
        </xsl:if>
        <xsl:if test="ends-with($data_type, '64')">
            <xsl:attribute name="length">64</xsl:attribute>
        </xsl:if>
    </xsl:function>

    <xsl:function name="acosar:int-to-hex" as="xs:string">
        <xsl:param name="in" as="xs:integer"/>
        <xsl:sequence
            select="concat('0x', substring(concat('000', acosar:int-to-hex-rec($in)), string-length(acosar:int-to-hex-rec($in)) + 1))"
        />
    </xsl:function>

    <xsl:template match="/DcpOverCan">
        <NetworkDefinition xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://kayak.2codeornot2code.org/1.0"
            xsi:noNamespaceSchemaLocation="https://raw.githubusercontent.com/dschanoeh/Kayak/master/Kayak-kcd/src/main/resources/com/github/kayak/canio/kcd/loader/Definition.xsd">
            <Document name="DCP CAN Message Catalog" version="1.0" author="DCP_over_CAN_to_KCD.xsl"
                company="" date=""/>

            <xsl:if test="KMatrix/STC_register">
                <Node id="0" name="master"/>
            </xsl:if>
            <xsl:for-each select="ScenarioConfiguration/DcpSlave">

                <xsl:choose>
                    <xsl:when test="@name">
                        <Node id="{@dcpId}" name="{@name}"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <Node id="{@dcpId}" name="DCP Slave {@dcpId}"/>
                    </xsl:otherwise>
                </xsl:choose>

            </xsl:for-each>

            <Bus name="DCP Scenario">
                <!-- ToDo include Metainformation for Bus name-->
                <xsl:for-each
                    select="KMatrix/*[starts-with(name(), 'INF_') or starts-with(name(), 'STC_') or starts-with(name(), 'NTF_') or starts-with(name(), 'RSP_')]">
                    <xsl:variable name="msg_name" select="name()"/>
                    <Message id="{acosar:int-to-hex(./@canId)}" length="{@length}">
                        <xsl:choose>
                            <xsl:when
                                test="starts-with(name(), 'NTF_') or starts-with(name(), 'RSP_')">
                                <xsl:attribute name="name">
                                    <xsl:value-of
                                        select="concat(concat(name(), ' sender='), @senderRef)"/>
                                </xsl:attribute>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:attribute name="name">
                                    <xsl:value-of select="name()"/>
                                </xsl:attribute>
                            </xsl:otherwise>
                        </xsl:choose>

                        <Producer>
                            <NodeRef id="{./@senderRef}"/>
                        </Producer>
                        <xsl:for-each select="./@*[starts-with(name(), 'f_')]">
                            <xsl:variable name="offset" select="."/>
                            <xsl:variable name="signal_name" select="name()"/>

                            <xsl:if test="$offset and $offset != 'H'">
                                <Signal>
                                    <xsl:attribute name="name">
                                        <xsl:value-of select="substring(name(), 3)"/>
                                    </xsl:attribute>

                                    <xsl:attribute name="offset">
                                        <xsl:value-of select="number($offset) * 8"/>
                                    </xsl:attribute>
                                    <xsl:variable name="data_type"
                                        select="/DcpOverCan/KMatrix/@*[starts-with(name(), $signal_name) and ends-with(name(), '_data_type')]"/>
                                    <xsl:variable name="endianess"
                                        select="/DcpOverCan/KMatrix/@*[starts-with(name(), $signal_name) and ends-with(name(), '_endianess')]"/>

                                    <xsl:attribute name="endianess">
                                        <xsl:value-of select="$endianess"/>
                                    </xsl:attribute>

                                    <xsl:if test="$data_type = 0 or $data_type = 4">
                                        <xsl:attribute name="length">8</xsl:attribute>
                                    </xsl:if>
                                    <xsl:if test="$data_type = 1 or $data_type = 5">
                                        <xsl:attribute name="length">16</xsl:attribute>
                                    </xsl:if>
                                    <xsl:if
                                        test="$data_type = 2 or $data_type = 6 or $data_type = 8">
                                        <xsl:attribute name="length">32</xsl:attribute>
                                    </xsl:if>
                                    <xsl:if
                                        test="$data_type = 3 or $data_type = 7 or $data_type = 9">
                                        <xsl:attribute name="length">64</xsl:attribute>
                                    </xsl:if>
                                    <xsl:choose>
                                        <xsl:when
                                            test="starts-with($msg_name, 'INF_') or starts-with($msg_name, 'STC_')">
                                            <Consumer>
                                                <xsl:for-each
                                                  select="/DcpOverCan/ScenarioConfiguration/DcpSlave">
                                                  <NodeRef id="{@dcpId}"/>
                                                </xsl:for-each>
                                            </Consumer>
                                        </xsl:when>
                                        <xsl:when
                                            test="starts-with($msg_name, 'NTF_') or starts-with($msg_name, 'RSP_')">
                                            <Consumer>
                                                <NodeRef id="0"/>
                                            </Consumer>
                                        </xsl:when>
                                    </xsl:choose>
                                    <xsl:choose>
                                        <xsl:when test="$data_type = 8">
                                            <Value type="single"/>
                                        </xsl:when>
                                        <xsl:when test="$data_type = 9">
                                            <Value type="double"/>
                                        </xsl:when>
                                        <xsl:when test="$data_type &lt;= 4">
                                            <Value type="unsigned"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <Value type="signed"/>
                                        </xsl:otherwise>
                                    </xsl:choose>

                                </Signal>
                            </xsl:if>
                        </xsl:for-each>

                    </Message>
                </xsl:for-each>

                <!-- Data -->
                <xsl:for-each select="KMatrix/*[starts-with(name(), 'DAT_')]">
                    <xsl:variable name="msg_name" select="name()"/>

                    <Message id="{acosar:int-to-hex(./@canId)}" length="{@length}">

                        <xsl:if test="name() = 'DAT_input_output'">
                            <xsl:attribute name="name">
                                <xsl:value-of select="concat(concat(name(), ' data_id='), @dataId)"
                                />
                            </xsl:attribute>
                        </xsl:if>
                        <xsl:if test="name() = 'DAT_parameter'">
                            <xsl:attribute name="name">
                                <xsl:value-of
                                    select="concat(concat(name(), ' param_id='), @paramId)"/>
                            </xsl:attribute>
                        </xsl:if>
                        <Producer>
                            <NodeRef id="{./@senderRef}"/>
                        </Producer>
                        <xsl:for-each select="./Payload">
                            <xsl:sort data-type="number" select="@pos"/>
                            <Signal name="{@name}">
                                <xsl:attribute name="offset">
                                    <xsl:value-of select="@offset * 8"/>
                                </xsl:attribute>
                                <xsl:choose>
                                    <xsl:when test="./Int8">
                                        <xsl:attribute name="length">8</xsl:attribute>
                                        <xsl:attribute name="endianess">
                                            <xsl:value-of select="./Int8/@endianess"/>
                                        </xsl:attribute>
                                    </xsl:when>
                                    <xsl:when test="./Int16">
                                        <xsl:attribute name="length">16</xsl:attribute>
                                        <xsl:attribute name="endianess">
                                            <xsl:value-of select="./Int16/@endianess"/>
                                        </xsl:attribute>
                                    </xsl:when>
                                    <xsl:when test="./Int32">
                                        <xsl:attribute name="length">32</xsl:attribute>
                                        <xsl:attribute name="endianess">
                                            <xsl:value-of select="./Int32/@endianess"/>
                                        </xsl:attribute>
                                    </xsl:when>
                                    <xsl:when test="./Int64">
                                        <xsl:attribute name="length">64</xsl:attribute>
                                        <xsl:attribute name="endianess">
                                            <xsl:value-of select="./Int64/@endianess"/>
                                        </xsl:attribute>
                                    </xsl:when>
                                    <xsl:when test="./Uint8">
                                        <xsl:attribute name="length">8</xsl:attribute>
                                        <xsl:attribute name="endianess">
                                            <xsl:value-of select="./Uint8/@endianess"/>
                                        </xsl:attribute>
                                    </xsl:when>
                                    <xsl:when test="./Uint16">
                                        <xsl:attribute name="length">16</xsl:attribute>
                                        <xsl:attribute name="endianess">
                                            <xsl:value-of select="./Uint16/@endianess"/>
                                        </xsl:attribute>
                                    </xsl:when>
                                    <xsl:when test="./Uint32">
                                        <xsl:attribute name="length">32</xsl:attribute>
                                        <xsl:attribute name="endianess">
                                            <xsl:value-of select="./Uint32/@endianess"/>
                                        </xsl:attribute>
                                    </xsl:when>
                                    <xsl:when test="./Uint64">
                                        <xsl:attribute name="length">64</xsl:attribute>
                                        <xsl:attribute name="endianess">
                                            <xsl:value-of select="./Uint64/@endianess"/>
                                        </xsl:attribute>
                                    </xsl:when>
                                    <xsl:when test="./Float32">
                                        <xsl:attribute name="length">32</xsl:attribute>
                                        <xsl:attribute name="endianess">
                                            <xsl:value-of select="./Float32/@endianess"/>
                                        </xsl:attribute>
                                    </xsl:when>
                                    <xsl:when test="./Float64">
                                        <xsl:attribute name="length">64</xsl:attribute>
                                        <xsl:attribute name="endianess">
                                            <xsl:value-of select="./Float64/@endianess"/>
                                        </xsl:attribute>
                                    </xsl:when>
                                    <xsl:when test="./String">
                                        <xsl:attribute name="length">
                                            <xsl:value-of select="./String/@length"/>
                                        </xsl:attribute>
                                        <xsl:attribute name="endianess">
                                            <xsl:value-of select="./String/@endianess"/>
                                        </xsl:attribute>
                                    </xsl:when>
                                    <xsl:when test="./Binary">
                                        <xsl:attribute name="length">
                                            <xsl:value-of select="./Binary/@length"/>
                                        </xsl:attribute>
                                        <xsl:attribute name="endianess">
                                            <xsl:value-of select="./Binary/@endianess"/>
                                        </xsl:attribute>
                                    </xsl:when>
                                </xsl:choose>
                                <Consumer>
                                    <xsl:for-each select="../Receiver">
                                        <NodeRef id="{@dcpId}"/>
                                    </xsl:for-each>
                                </Consumer>

                                <xsl:choose>
                                    <xsl:when test="./Int8">
                                        <Value type="signed">
                                            <xsl:if test="./Int8/@min">
                                                <xsl:attribute name="min">
                                                  <xsl:value-of select="./Int8/@min"/>
                                                </xsl:attribute>
                                            </xsl:if>
                                            <xsl:if test="./Int8/@max">
                                                <xsl:attribute name="max">
                                                  <xsl:value-of select="./Int8/@max"/>
                                                </xsl:attribute>
                                            </xsl:if>
                                        </Value>
                                    </xsl:when>
                                    <xsl:when test="./Int16">
                                        <Value type="signed">
                                            <xsl:if test="./Int16/@min">
                                                <xsl:attribute name="min">
                                                  <xsl:value-of select="./Int16/@min"/>
                                                </xsl:attribute>
                                            </xsl:if>
                                            <xsl:if test="./Int16/@max">
                                                <xsl:attribute name="max">
                                                  <xsl:value-of select="./Int16/@max"/>
                                                </xsl:attribute>
                                            </xsl:if>
                                        </Value>
                                    </xsl:when>
                                    <xsl:when test="./Int32">
                                        <Value type="signed">
                                            <xsl:if test="./Int32/@min">
                                                <xsl:attribute name="min">
                                                  <xsl:value-of select="./Int32/@min"/>
                                                </xsl:attribute>
                                            </xsl:if>
                                            <xsl:if test="./Int32/@max">
                                                <xsl:attribute name="max">
                                                  <xsl:value-of select="./Int32/@max"/>
                                                </xsl:attribute>
                                            </xsl:if>
                                        </Value>
                                    </xsl:when>
                                    <xsl:when test="./Int64">
                                        <Value type="signed">
                                            <xsl:if test="./Int64/@min">
                                                <xsl:attribute name="min">
                                                  <xsl:value-of select="./Int64/@min"/>
                                                </xsl:attribute>
                                            </xsl:if>
                                            <xsl:if test="./Int64/@max">
                                                <xsl:attribute name="max">
                                                  <xsl:value-of select="./Int64/@max"/>
                                                </xsl:attribute>
                                            </xsl:if>
                                        </Value>
                                    </xsl:when>
                                    <xsl:when test="./Uint8">
                                        <Value type="unsigned">
                                            <xsl:if test="./Uint8/@min">
                                                <xsl:attribute name="min">
                                                  <xsl:value-of select="./Uint8/@min"/>
                                                </xsl:attribute>
                                            </xsl:if>
                                            <xsl:if test="./Uint8/@max">
                                                <xsl:attribute name="max">
                                                  <xsl:value-of select="./Uint8/@max"/>
                                                </xsl:attribute>
                                            </xsl:if>
                                        </Value>
                                    </xsl:when>
                                    <xsl:when test="./Uint16">
                                        <Value type="unsigned">
                                            <xsl:if test="./Uint16/@min">
                                                <xsl:attribute name="min">
                                                  <xsl:value-of select="./Uint16/@min"/>
                                                </xsl:attribute>
                                            </xsl:if>
                                            <xsl:if test="./Uint16/@max">
                                                <xsl:attribute name="max">
                                                  <xsl:value-of select="./Uint16/@max"/>
                                                </xsl:attribute>
                                            </xsl:if>
                                        </Value>
                                    </xsl:when>
                                    <xsl:when test="./Uint32">
                                        <Value type="unsigned">
                                            <xsl:if test="./Uint32/@min">
                                                <xsl:attribute name="min">
                                                  <xsl:value-of select="./Uint32/@min"/>
                                                </xsl:attribute>
                                            </xsl:if>
                                            <xsl:if test="./Uint32/@max">
                                                <xsl:attribute name="max">
                                                  <xsl:value-of select="./Uint32/@max"/>
                                                </xsl:attribute>
                                            </xsl:if>
                                        </Value>
                                    </xsl:when>
                                    <xsl:when test="./Uint64">
                                        <Value type="unsigned">
                                            <xsl:if test="./Uint64/@min">
                                                <xsl:attribute name="min">
                                                  <xsl:value-of select="./Uint64/@min"/>
                                                </xsl:attribute>
                                            </xsl:if>
                                            <xsl:if test="./Uint64/@max">
                                                <xsl:attribute name="max">
                                                  <xsl:value-of select="./Uint64/@max"/>
                                                </xsl:attribute>
                                            </xsl:if>
                                        </Value>
                                    </xsl:when>
                                    <xsl:when test="./Float32">
                                        <Value type="single">
                                            <xsl:if test="./Float32/@min">
                                                <xsl:attribute name="min">
                                                  <xsl:value-of select="./Float32/@min"/>
                                                </xsl:attribute>
                                            </xsl:if>
                                            <xsl:if test="./Float32/@max">
                                                <xsl:attribute name="max">
                                                  <xsl:value-of select="./Float32/@max"/>
                                                </xsl:attribute>
                                            </xsl:if>
                                        </Value>
                                    </xsl:when>
                                    <xsl:when test="./Float64">
                                        <Value type="double">
                                            <xsl:if test="./Float64/@min">
                                                <xsl:attribute name="min">
                                                  <xsl:value-of select="./Float64/@min"/>
                                                </xsl:attribute>
                                            </xsl:if>
                                            <xsl:if test="./Float64/@max">
                                                <xsl:attribute name="max">
                                                  <xsl:value-of select="./Float64/@max"/>
                                                </xsl:attribute>
                                            </xsl:if>
                                        </Value>
                                    </xsl:when>
                                    <xsl:when test="./String">
                                        <Value type="unsigned"/>
                                    </xsl:when>
                                    <xsl:when test="./Binary">
                                        <Value type="unsigned"/>
                                    </xsl:when>
                                </xsl:choose>
                            </Signal>
                        </xsl:for-each>

                    </Message>

                </xsl:for-each>

            </Bus>
        </NetworkDefinition>
    </xsl:template>
</xsl:stylesheet>
