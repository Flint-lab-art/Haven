package com.haven.backend.ledger.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.haven.backend.ledger.entity.LedgerAliases;
import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Param;

import java.util.UUID;

public interface LedgerAliasesMapper extends BaseMapper<LedgerAliases> {

    /**
     * 新增或覆盖别名分类。
     */
    @Insert("""
            insert into ledger_aliases (user_id, alias, category)
            values (#{userId, typeHandler=com.haven.backend.typehandler.UuidTypeHandler},
                    #{alias}, #{category})
            on conflict (user_id, alias) do update set category = excluded.category
            """)
    int upsert(@Param("userId") UUID userId,
               @Param("alias") String alias,
               @Param("category") String category);
}
