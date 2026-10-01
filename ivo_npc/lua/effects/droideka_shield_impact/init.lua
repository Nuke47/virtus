local matRing = Material("effects/select_ring")
local matGlow = Material("sprites/light_glow02_add")

function EFFECT:Init( data )
    self.ShieldCenter = data:GetOrigin()
    self.Normal = data:GetNormal() 
    self.Radius = data:GetRadius()
    self.Ent = data:GetEntity()
    
    if not self.Radius or self.Radius == 0 then 
        self.Radius = 43 
    end
    
    self.LifeTime = math.Rand(0.4, 0.6)
    self.DieTime = CurTime() + self.LifeTime
    
    -- Â¿CuÃ¡nto viaja la onda? Aleatorio entre 50 y 75 grados para que mÃºltiples disparos no se superpongan exactamente.
    self.MaxTheta = math.rad(math.Rand(50, 75))
end

function EFFECT:Think()
    return ( CurTime() < self.DieTime )
end

function EFFECT:Render()
    local fraction = ( self.DieTime - CurTime() ) / self.LifeTime
    fraction = math.Clamp( fraction, 0, 1 )
    local t = 1 - fraction -- de 0 a 1 (tiempo transcurrido)
    
    -- Actualizar el centro si el droideka se está moviendo
    if IsValid(self.Ent) then
        self.ShieldCenter = self.Ent:GetPos() + Vector(0,0,35)
    end
    
    -- Easing out (comienza rÃ¡pido y se ralentiza)
    local easeT = math.sin(t * math.pi / 2)
    local theta = self.MaxTheta * easeT
    
    -- AÃ±adimos un margen extra al radio para que el cÃ­rculo se dibuje 
    -- levÃ­simamente por fuera del modelo de colisiÃ³n y no haya recortes (Z-fighting).
    local virtualRadius = self.Radius + 1
    
    -- MAGIA MATEMÃTICA:
    -- La intersecciÃ³n de una esfera con un plano es un cÃ­rculo perfecto.
    -- Si empujamos el plano del quad hacia el centro del escudo mientras crece,
    -- el borde visible del cÃ­rculo (la textura del anillo) recorrerÃ¡ la 
    -- superficie de la esfera sin separarse jamÃ¡s de ella.
    
    local ringRadius = virtualRadius * math.sin(theta)
    local planeDist = virtualRadius * math.cos(theta)
    
    -- Para materiales aditivos en Source Engine, la opacidad real se logra oscureciendo el color (RGB)
    -- a medida que se expande, hasta llegar a negro (invisible).
    local fade = fraction
    local r = 30 * fade
    local g = 160 * fade
    local b = 255 * fade
    local col = Color( r, g, b, 255 )
    
    -- PosiciÃ³n del centro del Quad (plano intersectando la esfera)
    local pos = self.ShieldCenter + self.Normal * planeDist

    -- Usamos el material aditivo suave
    render.SetMaterial( matGlow )
    
    -- DIBUJAR UN ANILLO 3D FINO CON MESH
    -- Grosor moderado, pero gracias al mapeo UV, los bordes serÃ¡n translÃºcidos y suaves
    local thickness = 2.5 
    local segments = 48 -- MÃ¡s segmentos para que sea un cÃ­rculo perfecto y no se vean picos
    local ang = self.Normal:Angle()
    local up = ang:Up()
    local right = ang:Right()
    
    mesh.Begin( MATERIAL_QUADS, segments )
    for i = 1, segments do
        local rad1 = (i - 1) * math.pi * 2 / segments
        local rad2 = i * math.pi * 2 / segments
        
        local c1, s1 = math.cos(rad1), math.sin(rad1)
        local c2, s2 = math.cos(rad2), math.sin(rad2)
        
        local p1_in  = pos + right * (c1 * (ringRadius - thickness)) + up * (s1 * (ringRadius - thickness))
        local p1_out = pos + right * (c1 * (ringRadius + thickness)) + up * (s1 * (ringRadius + thickness))
        local p2_in  = pos + right * (c2 * (ringRadius - thickness)) + up * (s2 * (ringRadius - thickness))
        local p2_out = pos + right * (c2 * (ringRadius + thickness)) + up * (s2 * (ringRadius + thickness))
        
        -- Mapeamos la textura del brillo (que es un punto difuminado).
        -- Al usar TexCoord (0.5, 0) para el exterior y (0.5, 1) para el interior,
        -- logramos que los bordes de la lÃ­nea se difuminen suavemente hacia la transparencia (antialiasing perfecto).
        
        mesh.Color( col.r, col.g, col.b, col.a )
        mesh.TexCoord( 0, 0.5, 0 ) -- Borde Exterior (Transparente)
        mesh.Position( p1_out )
        mesh.AdvanceVertex()
        
        mesh.Color( col.r, col.g, col.b, col.a )
        mesh.TexCoord( 0, 0.5, 0 ) -- Borde Exterior (Transparente)
        mesh.Position( p2_out )
        mesh.AdvanceVertex()
        
        mesh.Color( col.r, col.g, col.b, col.a )
        mesh.TexCoord( 0, 0.5, 1 ) -- Borde Interior (Transparente)
        mesh.Position( p2_in )
        mesh.AdvanceVertex()
        
        mesh.Color( col.r, col.g, col.b, col.a )
        mesh.TexCoord( 0, 0.5, 1 ) -- Borde Interior (Transparente)
        mesh.Position( p1_in )
        mesh.AdvanceVertex()
    end
    mesh.End()
    
    -- Brillo central en el punto exacto de impacto al inicio
    if t < 0.3 then
        local glowFade = 1 - (t / 0.3)
        local impactPos = self.ShieldCenter + self.Normal * virtualRadius
        render.DrawQuadEasy( impactPos, self.Normal, 20, 20, Color(100 * glowFade, 200 * glowFade, 255 * glowFade, 255), 0 )
    end
end
