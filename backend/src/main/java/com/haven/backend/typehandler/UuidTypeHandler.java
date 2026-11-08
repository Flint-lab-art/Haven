package com.haven.backend.typehandler;

import org.apache.ibatis.type.BaseTypeHandler;
import org.apache.ibatis.type.JdbcType;
import org.apache.ibatis.type.MappedJdbcTypes;
import org.apache.ibatis.type.MappedTypes;

import java.sql.CallableStatement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.UUID;

/**
 * MyBatis TypeHandler：Java UUID ↔ PostgreSQL uuid。
 * <p>
 * PG JDBC 驱动返回 java.util.UUID 对象，MyBatis 默认不认识，
 * 需要此 Handler 做桥接。
 */
@MappedTypes(UUID.class)
@MappedJdbcTypes(JdbcType.OTHER)
public class UuidTypeHandler extends BaseTypeHandler<UUID> {

    @Override
    public void setNonNullParameter(PreparedStatement ps, int i, UUID parameter, JdbcType jdbcType)
            throws SQLException {
        ps.setObject(i, parameter, java.sql.Types.OTHER);
    }

    @Override
    public UUID getNullableResult(ResultSet rs, String columnName) throws SQLException {
        Object val = rs.getObject(columnName);
        if (val == null) return null;
        if (val instanceof UUID u) return u;
        return UUID.fromString(val.toString());
    }

    @Override
    public UUID getNullableResult(ResultSet rs, int columnIndex) throws SQLException {
        Object val = rs.getObject(columnIndex);
        if (val == null) return null;
        if (val instanceof UUID u) return u;
        return UUID.fromString(val.toString());
    }

    @Override
    public UUID getNullableResult(CallableStatement cs, int columnIndex) throws SQLException {
        Object val = cs.getObject(columnIndex);
        if (val == null) return null;
        if (val instanceof UUID u) return u;
        return UUID.fromString(val.toString());
    }
}
