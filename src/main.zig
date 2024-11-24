const std = @import("std");

const R = @import("raylib");
const b2 = @import("box2d");

const Entity = struct {
    bodyId: b2.b2BodyId,
    extent: b2.b2Vec2,
    texture: R.Texture2D,

    fn draw(self: *Entity) void {
        // The boxes were created centered on the bodies, but raylib draws textures starting at the top left corner.
        // b2Body_GetWorldPoint gets the top left corner of the box accounting for rotation.
        const p = b2.b2Body_GetWorldPoint(self.bodyId, .{ .x = -self.extent.x, .y = -self.extent.y });
        const rotation = b2.b2Body_GetRotation(self.bodyId);
        const radians = b2.b2Rot_GetAngle(rotation);

        R.DrawTextureEx(self.texture, .{ .x = p.x, .y = p.y }, R.RAD2DEG * radians, 1.0, R.WHITE);
    }
};

const GROUND_COUNT = 14;
const BOX_COUNT = 10;

pub fn main() !void {
    const width = 1920;
    const height = 1080;
    R.InitWindow(width, height, "box2d-raylib");
    R.SetTargetFPS(60);

    // 128 pixels per meter is a appropriate for this scene. The boxes are 128 pixels wide.
    const lengthUnitsPerMeter = 128.0;
    b2.b2SetLengthUnitsPerMeter(lengthUnitsPerMeter);

    var worldDef = b2.b2DefaultWorldDef();

    // Realistic gravity is achieved by multiplying gravity by the length unit.
    worldDef.gravity.y = 9.8 * lengthUnitsPerMeter;
    const worldId = b2.b2CreateWorld(&worldDef);

    const groundTexture = R.LoadTexture("assets/ground.png");
    const boxTexture = R.LoadTexture("assets/box.png");

    const groundExtent: b2.b2Vec2 = .{
        .x = 0.5 * @as(f32, @floatFromInt(groundTexture.width)),
        .y = 0.5 * @as(f32, @floatFromInt(groundTexture.height)),
    };
    const boxExtent: b2.b2Vec2 = .{
        .x = 0.5 * @as(f32, @floatFromInt(boxTexture.width)),
        .y = 0.5 * @as(f32, @floatFromInt(boxTexture.height)),
    };

    // These polygons are centered on the origin and when they are added to a body they
    // will be centered on the body position.
    const groundPolygon = b2.b2MakeBox(groundExtent.x, groundExtent.y);
    const boxPolygon = b2.b2MakeBox(boxExtent.x, boxExtent.y);

    var groundEntities: [GROUND_COUNT]Entity = undefined;
    for (0..GROUND_COUNT) |i| {
        const entity = &groundEntities[i];
        var bodyDef = b2.b2DefaultBodyDef();
        bodyDef.position = .{
            .x = (2.0 * @as(f32, @floatFromInt(i)) + 2.0) * groundExtent.x,
            .y = height - groundExtent.y - 100.0,
        };

        // I used this rotation to test the world to screen transformation
        //bodyDef.rotation = b2MakeRot(0.25f * b2_pi * i);

        entity.bodyId = b2.b2CreateBody(worldId, &bodyDef);
        entity.extent = groundExtent;
        entity.texture = groundTexture;
        const shapeDef = b2.b2DefaultShapeDef();
        _ = b2.b2CreatePolygonShape(entity.bodyId, &shapeDef, &groundPolygon);
    }

    var boxEntities: [BOX_COUNT]Entity = undefined;
    var boxIndex: usize = 0;
    for (0..4) |i| {
        const y = height - groundExtent.y - 100.0 - (2.5 * @as(f32, @floatFromInt(i)) + 2.0) * boxExtent.y - 20.0;

        for (i..4) |j| {
            const x = 0.5 * width + (3.0 * @as(f32, @floatFromInt(j)) - @as(f32, @floatFromInt(i)) - 3.0) * boxExtent.x;
            std.debug.assert(boxIndex < BOX_COUNT);

            const entity = &boxEntities[boxIndex];
            var bodyDef = b2.b2DefaultBodyDef();
            bodyDef.type = b2.b2_dynamicBody;
            bodyDef.position = .{
                .x = x,
                .y = y,
            };
            entity.bodyId = b2.b2CreateBody(worldId, &bodyDef);
            entity.texture = boxTexture;
            entity.extent = boxExtent;
            const shapeDef = b2.b2DefaultShapeDef();
            _ = b2.b2CreatePolygonShape(entity.bodyId, &shapeDef, &boxPolygon);

            boxIndex += 1;
        }
    }

    var pause: bool = false;

    while (!R.WindowShouldClose()) {
        if (R.IsKeyPressed(R.KEY_P)) {
            pause = !pause;
        }

        if (pause == false) {
            const deltaTime = R.GetFrameTime();
            b2.b2World_Step(worldId, deltaTime, 4);
        }

        R.BeginDrawing();
        R.ClearBackground(R.DARKGRAY);

        const message = "Hello Box2D with Zig!";
        const fontSize = 36;
        const textWidth = R.MeasureText(message, fontSize);
        R.DrawText(message, @divFloor(width - textWidth, 2), 50, fontSize, R.LIGHTGRAY);

        for (0..GROUND_COUNT) |i| {
            groundEntities[i].draw();
        }

        for (0..BOX_COUNT) |i| {
            boxEntities[i].draw();
        }

        R.EndDrawing();
    }

    R.UnloadTexture(groundTexture);
    R.UnloadTexture(boxTexture);

    R.CloseWindow();
}
