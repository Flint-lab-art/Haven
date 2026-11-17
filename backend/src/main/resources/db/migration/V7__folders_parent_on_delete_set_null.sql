-- 父文件夹删除时不再级联删除子文件夹。
-- 原来的 ON DELETE CASCADE 会跨用户传播：只要 parent_id 指向他人文件夹，
-- 他人删除自己的文件夹就会连带删除你的整棵子树。
-- 同用户子树的级联删除由 FoldersServiceImpl.cascadeDelete 按 user_id 显式处理。
ALTER TABLE folders DROP CONSTRAINT folders_parent_id_fkey;

ALTER TABLE folders
    ADD CONSTRAINT folders_parent_id_fkey
        FOREIGN KEY (parent_id) REFERENCES folders (id) ON DELETE SET NULL;
