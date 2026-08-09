import { IsInt, IsOptional, IsString, Max, Min } from 'class-validator';
import { Transform } from 'class-transformer';

export class ConfirmResultDto {
  @IsString() hallTicket: string;

  @IsOptional()
  @Transform(({ value, obj }) => {
    const raw = value ?? obj.year ?? 1;
    return Number(raw);
  })
  @IsInt()
  @Min(1)
  @Max(8)
  semester?: number;

  @IsOptional()
  @Transform(({ value }) => (value !== undefined ? Number(value) : undefined))
  year?: number;

  @IsString() s3Key: string;
  @IsOptional() @IsString() publicUrl?: string;
}
