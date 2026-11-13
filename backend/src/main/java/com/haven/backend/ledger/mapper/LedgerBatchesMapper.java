package com.haven.backend.ledger.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.haven.backend.ledger.entity.LedgerBatches;
import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Param;

public interface LedgerBatchesMapper extends BaseMapper<LedgerBatches> {

    /**
     * 幂等写入批次。
     *
     * @return 1 表示本次新写入，0 表示该 batch_id 已存在
     */
    @Insert("""
            insert into ledger_batches (user_id, batch_id, raw_text, created_at)
            values (#{batch.userId, typeHandler=com.haven.backend.typehandler.UuidTypeHandler},
                    #{batch.batchId}, #{batch.rawText}, #{batch.createdAt})
            on conflict (user_id, batch_id) do nothing
            """)
    int insertIfAbsent(@Param("batch") LedgerBatches batch);
}
