IVO_SAM = IVO_SAM or {}
IVO_SAM.DB = IVO_SAM.DB or {}

if IVO_SAM.Config.USE_MYSQL then
    require("mysqloo")
    
    local db = mysqloo.connect(
        IVO_SAM.Config.DB_HOST, 
        IVO_SAM.Config.DB_USER, 
        IVO_SAM.Config.DB_PASS, 
        IVO_SAM.Config.DB_NAME, 
        IVO_SAM.Config.DB_PORT
    )
    
    function db:onConnected()
        print("[IVOSAM] MySQL Connected!")
        hook.Run("IVOSAM_DatabaseConnected")
    end
    
    function db:onConnectionFailed(err)
        print("[IVOSAM] MySQL Connection Failed: " .. err)
    end
    
    db:connect()
    IVO_SAM.DB.Connection = db
    
    function IVO_SAM.DB.Query(queryStr, callback)
        if not IVO_SAM.DB.Connection then return end
        local q = IVO_SAM.DB.Connection:query(queryStr)
        q.onSuccess = function(_, data)
            if data and #data == 0 then data = nil end
            if callback then callback(data) end
        end
        q.onError = function(_, err)
            if not string.match(err, "Duplicate column name") then print("[IVOSAM] MySQL Error: " .. err .. " (Query: " .. queryStr .. ")") end
            if callback then callback(false, err) end
        end
        q:start()
    end

    function IVO_SAM.DB.QueryRow(queryStr, callback)
        IVO_SAM.DB.Query(queryStr, function(data, err)
            if data == false then
                if callback then callback(false, err) end
            elseif data and data[1] then
                if callback then callback(data[1]) end
            else
                if callback then callback(nil) end
            end
        end)
    end
    
    function IVO_SAM.DB.Escape(str)
        if not IVO_SAM.DB.Connection then return sql.SQLStr(str) end
        return "'" .. IVO_SAM.DB.Connection:escape(tostring(str)) .. "'"
    end
else
    function IVO_SAM.DB.Query(queryStr, callback)
        local data = sql.Query(queryStr)
        if data == false then
            print("[IVOSAM] SQLite Error: " .. sql.LastError() .. " (Query: " .. queryStr .. ")")
            if callback then callback(false, sql.LastError()) end
        else
            if callback then callback(data) end
        end
    end
    
    function IVO_SAM.DB.QueryRow(queryStr, callback)
        local data = sql.QueryRow(queryStr)
        if data == false then
            print("[IVOSAM] SQLite Error: " .. sql.LastError() .. " (Query: " .. queryStr .. ")")
            if callback then callback(false, sql.LastError()) end
        else
            if callback then callback(data) end
        end
    end

    function IVO_SAM.DB.Escape(str)
        return sql.SQLStr(str)
    end
    
    timer.Simple(0, function() hook.Run("IVOSAM_DatabaseConnected") end)
end

