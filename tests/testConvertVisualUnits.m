classdef testConvertVisualUnits < matlab.unittest.TestCase
    methods(Test)
        function testRoundTripDeg(testCase)
            x = 5; % deg
            px = convertVisualUnits(x, 'deg', 'px');
            back = convertVisualUnits(px, 'px', 'deg');
            testCase.verifyLessThan(abs(back - x), 1e-6);
        end
        function testPxToDegConsistency(testCase)
            px = 100;
            deg = convertVisualUnits(px, 'px', 'deg');
            testCase.verifyGreaterThan(deg, 0);
        end
        function testDefaultGeometry(testCase)
            % Verify conversion with hardcoded defaults
            % Defaults: distance=630mm, res=1920x1080, size=340x190mm
            deg = 5;
            px = convertVisualUnits(deg, 'deg', 'px');

            % Result should be finite and positive
            testCase.verifyTrue(isfinite(px), 'Pixels should be finite');
            testCase.verifyGreaterThan(px, 0, 'Pixels should be positive');

            % Round-trip should preserve value
            back = convertVisualUnits(px, 'px', 'deg');
            testCase.verifyLessThan(abs(back - deg), 1e-6);
        end
        function testCustomGeometry(testCase)
            % Test with explicit custom geometry parameters
            deg = 8;
            distance = 500; % mm
            resX = 1024;
            resY = 768;
            sizeX = 400; % mm
            sizeY = 300; % mm

            px = convertVisualUnits(deg, 'deg', 'px', distance, resX, resY, sizeX, sizeY);

            % Verify finite output
            testCase.verifyTrue(isfinite(px), 'Custom geometry should produce finite pixels');
            testCase.verifyGreaterThan(px, 0);

            % Round-trip with same geometry
            back = convertVisualUnits(px, 'px', 'deg', distance, resX, resY, sizeX, sizeY);
            testCase.verifyLessThan(abs(back - deg), 1e-5, ...
                'Round-trip with custom geometry should preserve value');
        end
        function testDifferentGeometryProducesDifferentResults(testCase)
            % Same deg should produce different px for different geometries
            deg = 10;

            % Default geometry
            px1 = convertVisualUnits(deg, 'deg', 'px');

            % Custom geometry (closer screen, smaller size)
            px2 = convertVisualUnits(deg, 'deg', 'px', 400, 1920, 1080, 250, 140);

            % Should be different
            testCase.verifyNotEqual(px1, px2, 'AbsTol', 1, ...
                'Different screen geometries should produce different pixel values');
        end
        function testMmIntermediateSpace(testCase)
            % Test mm as intermediate canonical space
            deg = 6;
            mm = convertVisualUnits(deg, 'deg', 'mm');

            % mm should be positive and finite
            testCase.verifyTrue(isfinite(mm));
            testCase.verifyGreaterThan(mm, 0);

            % Convert mm to px
            px = convertVisualUnits(mm, 'mm', 'px');
            testCase.verifyTrue(isfinite(px));
            testCase.verifyGreaterThan(px, 0);

            % Full round-trip deg -> mm -> px -> mm -> deg
            back_mm = convertVisualUnits(px, 'px', 'mm');
            back_deg = convertVisualUnits(back_mm, 'mm', 'deg');
            testCase.verifyLessThan(abs(back_deg - deg), 1e-5);
        end
        function testNoNaNsWithValidInputs(testCase)
            % Ensure no NaNs with valid inputs
            values = [1, 5, 10, 15];
            for v = values
                px = convertVisualUnits(v, 'deg', 'px');
                testCase.verifyFalse(isnan(px), sprintf('deg=%d should not produce NaN', v));

                deg = convertVisualUnits(v, 'px', 'deg');
                testCase.verifyFalse(isnan(deg), sprintf('px=%d should not produce NaN', v));
            end
        end
    end
end

