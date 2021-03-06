local modename = ...
local _M = {}
_G[modename] = _M
package.loaded[modename] = _M

local zce = require("zce.core")
local lu = require("util.luaunit")
local cjson = require("cjson")
local cfg = require("hawk.config")
local hr = require("hawk.role.role")

--[[
{
    orgid : {
        owneriid : xxx, orgname : xxxx
    }
}
--]]
local _ORG = {}

--获取所有组织列表
function _M.getAllOrgs()
    local ok, res = zce.rdb_query(cfg.pgsqldb.dbobj, "select * from roles_orgs where enabled = true")
    if (ok and #res > 0) then
        _ORG = {}
        for i = 1, #res do
            _ORG[res[i].orgid] = res[i]
        end        
        return _ORG
    end
    return nil
end

-- 获取ORG信息
function _M.getOrg(orgid)
    if (_ORG[orgid] ~= nil) then
        return _ORG[orgid]
    end
    local ok, res = zce.rdb_query(cfg.pgsqldb.dbobj, "select * from roles_orgs where orgid = ? and enabled = true", orgid)
    if (ok and #res > 0) then
        _ORG[orgid] = res[1]
        return res[1]
    end
    return nil
end

function _M.addOrg(orgname, iid, orgfullname)
    
    local ok, res = zce.rdb_query(cfg.pgsqldb.dbobj, "select * from roles_orgs where orgname = ?", orgname)
    if (ok and #res > 0) then
        local org = res[1]
        if (org.enabled) then
            return false, org
        else
            local ok, upres = zce.rdb_query(cfg.pgsqldb.dbobj, 
                "update roles_orgs set enabled = true, owneriid= ?, orgfullname= ? where orgid = ?",
                iid, 
                orgfullname,
                org.orgid)

            org.enabled = true
            org.owneriid = iid
            org.orgfullname = orgfullname
            _ORG[res[1].orgid] = org

            hr.checkRoleRoot(org.orgid, 0)
            hr.clearUserRoleCache(iid)
            return true, org
        end
    end

    local ok, res = zce.rdb_query(cfg.pgsqldb.dbobj, 
        "insert into roles_orgs(orgname, owneriid, orgfullname, enabled) values(?, ?, ?, true) returning orgid", 
        orgname, 
        iid, 
        orgfullname)

    if (ok and #res > 0) then
        local org = { ['orgid'] = res[1].orgid, ['orgname'] = orgname, ['owneriid'] = iid, orgfullname = orgfullname}
        _ORG[res[1].orgid] = org

        hr.checkRoleRoot(org.orgid, 0)
        hr.clearUserRoleCache(iid)
        return true, org
    end
    return false, nil
end

function _M.editOrg(orgid, orgname, owneriid, orgfullname)
    local org = _M.getOrg(orgid)
    if org == nil then
        zce.log(1, "\t", "editOrg failed:", org, orgid, orgname, owneriid, orgfullname)
        return false, nil
    end

    zce.log(1, "\t", "editOrg:", orgid, orgname, owneriid, orgfullname)

    hr.clearUserRoleCache(owneriid)

    local ok, upres = zce.rdb_query(cfg.pgsqldb.dbobj, 
        "update roles_orgs set enabled = true, orgname= ?, owneriid= ?, orgfullname= ? where orgid = ?",
        orgname, 
        owneriid, 
        orgfullname, 
        orgid)

    org.enabled = true
    org.orgname = orgname
    org.owneriid = owneriid
    org.orgfullname = orgfullname
    _ORG[orgid] = org
    return true, org
end

function _M.delOrg(orgid, iid)
    local org = _M.getOrg(orgid)

    if (org == nil) then
        return false, "not exists"
    end

    -- if (org.owneriid  ~= iid) then
    --    return false, "not owner"
    -- end

    local children = hr.getRoleChildrenIds(orgid, 0) 
    if (children and #children > 2) then 
        return false, "not empty"
    end

    hr.clearUserRoleCache(iid)

    local ok, res = zce.rdb_query(cfg.pgsqldb.dbobj, "update roles_orgs set enabled = false where orgid = ?", orgid)
    if (ok and #res > 0) then
        zce.log(1, " ", "delOrg:", orgid)
        _ORG[orgid] = nil
        return true
    end
    return false, "dbfailed"
end

function _M.testOrg()
    local iid = 3
    local iid2 = 2

    local ok, org = _M.addOrg("TestOrg", iid)
    lu.assertNotEquals(org, nil)

    local ok = _M.delOrg(org.orgid, 0)
    lu.assertEquals(ok, false)

    local ok, err = _M.delOrg(org.orgid, iid)
    lu.assertEquals(ok, true)
    print (err)

    local ok, org = _M.addOrg("TestOrg", iid2)
    lu.assertNotEquals(org, nil)
    lu.assertEquals(org.owneriid, iid2)

    local ok = _M.delOrg(org.orgid, iid)
    lu.assertEquals(ok, false)

    local ok = _M.delOrg(org.orgid, iid2)
    lu.assertEquals(ok, true)
end
