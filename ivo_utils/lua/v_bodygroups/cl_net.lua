-- Cliente: lua/v_bodygroups/cl_net.lua
if not CLIENT then return end

v_bodygroups = v_bodygroups or {}

function v_bodygroups.NetworkUpdate(updateType, index, value)
    -- Validación de seguridad básica en el cliente
    if not updateType or not index or not value then return end

    net.Start("v_bodygroups_Update")
        net.WriteString(updateType)
        net.WriteInt(index, 8)
        net.WriteInt(value, 8)
        net.WriteString(LocalPlayer():GetModel()) -- Firma Anti-Contaminación
    net.SendToServer()
end