package com.haven.backend.typehandler;

import org.apache.ibatis.type.BaseTypeHandler;
import org.apache.ibatis.type.JdbcType;
import org.apache.ibatis.type.MappedJdbcTypes;
import org.apache.ibatis.type.MappedTypes;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * MyBatis TypeHandler：Java List<UUID> ↔ PostgreSQL uuid[]。
 */
@MappedTypes(List.class)
@MappedJdbcTypes(JdbcType.ARRAY)
public class UuidListTypeHandler extends BaseTypeHandler<List<UUID>> {

    @Override
    public void setNonNullParameter(PreparedStatement ps, int i, List<UUID> parameter, JdbcType jdbcType)
            throws SQLException {
        UUID[] arr = parameter.toArray(new UUID[0]);
        Connection conn = ps.getConnection();
        Array pgArray = conn.createArrayOf("uuid", arr);
        ps.setArray(i, pgArray);
    }

    @Override
    public List<UUID> getNullableResult(ResultSet rs, String columnName) throws SQLException {
        return toList(rs.getArray(columnName));
    }

    @Override
    public List<UUID> getNullableResult(ResultSet rs, int columnIndex) throws SQLException {
        return toList(rs.getArray(columnIndex));
    }

    @Override
    public List<UUID> getNullableResult(CallableStatement cs, int columnIndex) throws SQLException {
        return toList(cs.getArray(columnIndex));
    }

    private List<UUID> toList(Array pgArray) throws SQLException {
        if (pgArray == null) return null;
        Object[] javaArr = (Object[]) pgArray.getArray();
        List<UUID> list = new ArrayList<>(javaArr.length);
        for (Object o : javaArr) {
            if (o == null) continue;
            if (o instanceof UUID u) list.add(u);
            else list.add(UUID.fromString(o.toString()));
        }
        return list;
    }
}
